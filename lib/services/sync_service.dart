import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/employee.dart';
import 'storage_service.dart';
import 'sheets_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/absence.dart';
import 'package:intl/intl.dart' as intl;

class SyncService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SheetsService _sheets = SheetsService();
  
  List<Employee> _employees = [];
  List<Employee> get employees => _employees;
  
  bool _isOnline = false;
  bool get isOnline => _isOnline;
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  
  bool _isOfflineManual = false;
  bool get isOfflineManual => _isOfflineManual;

  String _locale = 'ar';
  String get locale => _locale;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  /// Tracks employee regs already notified for return-date today, to avoid
  /// repeating the same notification every 10-second cycle.
  Set<String> _notifiedToday = {};
  String _notifiedDate = '';   // the date _notifiedToday applies to


  Timer? _pollingTimer;
  final Connectivity _connectivity = Connectivity();

  SyncService() {
    _init();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/egm');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(settings: const InitializationSettings(android: android, iOS: ios));
    
    // Request permission for Android 13+
    if (Platform.isAndroid) {
      await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }

  Future<void> showNotification(String title, String body, {int id = 0}) async {
    const android = AndroidNotificationDetails(
      'absences_channel', 'Absences',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: android, iOS: ios),
    );
  }

  Future<void> checkReturnDates() async {
    final today = intl.DateFormat('yyyy/MM/dd').format(DateTime.now());
    final prefKey = 'notified_$today';

    // Reset the memory cache when date changes, load new set from storage
    if (_notifiedDate != today) {
      _notifiedDate = today;
      final savedStr = await _storage.loadString(prefKey);
      if (savedStr != null && savedStr.isNotEmpty) {
        _notifiedToday = Set<String>.from(json.decode(savedStr));
      } else {
        _notifiedToday.clear();
      }
    }

    bool updated = false;

    for (final employee in _employees) {
      final ab = employee.absence;
      if (ab == null || ab.returnDate == null) continue;
      if (ab.returnDate != today) continue;
      if (_notifiedToday.contains(employee.reg)) continue;

      final notifId = (employee.reg.hashCode.abs() % 90000) + 10000;
      await showNotification(
        'التحاق اليوم',
        '${employee.name} من المفترض أن تلتحق اليوم',
        id: notifId,
      );
      _notifiedToday.add(employee.reg);
      updated = true;
    }

    if (updated) {
      await _storage.saveString(prefKey, json.encode(_notifiedToday.toList()));
    }
  }


  Future<bool> _checkActualConnectivity() async {
    if (kIsWeb) return true;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updateOnlineStatus(ConnectivityResult result) async {
    bool online = result != ConnectivityResult.none;
    if (!online) {
      online = await _checkActualConnectivity();
    }
    if (_isOnline != online) {
      _isOnline = online;
      if (_isOnline) {
        _syncPendingActions();
      }
      notifyListeners();
    }
  }

  Future<void> _init() async {
    // 1. Load local data and theme immediately
    _employees = await _storage.loadEmployees();
    _isDarkMode = await _storage.loadThemeMode();
    _isOfflineManual = await _storage.loadBool('offline_manual');
    final savedLocale = await _storage.loadString('app_locale');
    if (savedLocale != null && savedLocale.isNotEmpty) {
      _locale = savedLocale;
    }
    notifyListeners();

    // 2. Monitor connectivity
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
      await _updateOnlineStatus(result);
    });

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    await _updateOnlineStatus(result);

    // 3. Start polling every 10 seconds + check return dates on startup
    _startPolling();
    await checkReturnDates();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!_isOnline) {
        final result = await _connectivity.checkConnectivity();
        await _updateOnlineStatus(result);
      }
      if (_isOnline && !_isSyncing && !_isOfflineManual) {
        await fetchFromSheets();
      }
      await checkReturnDates();
    });
  }

  Future<void> fetchFromSheets() async {
    // Prevent overwriting local changes if we haven't synced them yet
    final queue = await _storage.getSyncQueue();
    if (queue.isNotEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final remoteEmployees = await _sheets.fetchAll();
    if (remoteEmployees != null) {
      // Merge local absences to prevent them from disappearing 
      // if the backend (Google Sheets) doesn't store them correctly yet
      for (int i = 0; i < remoteEmployees.length; i++) {
        final remote = remoteEmployees[i];
        final localIdx = _employees.indexWhere((e) => e.reg == remote.reg);
        
        if (localIdx != -1) {
          final local = _employees[localIdx];
          
          // Only preserve local if remote returned null/empty
          final preserveAbs = remote.absence == null ? local.absence : remote.absence;
          final preserveArch = remote.archivedAbsences.isEmpty ? local.archivedAbsences : remote.archivedAbsences;
          
          remoteEmployees[i] = remote.copyWith(
            absence: preserveAbs,
            archivedAbsences: preserveArch,
          );
        }
      }
      
      _employees = remoteEmployees;
      await _storage.saveEmployees(_employees);
    }

    _isSyncing = false;
    notifyListeners();
  }

  // --- CRUD OPERATIONS ---

  Future<void> addEmployee(Employee employee) async {
    _employees.add(employee);
    await _storage.saveEmployees(_employees);
    notifyListeners();

    if (_isOnline && !_isOfflineManual) {
      final success = await _sheets.addEmployee(employee);
      if (!success) {
        await _storage.addToSyncQueue({'action': 'add', 'data': employee.toMap()});
      }
    } else {
      await _storage.addToSyncQueue({'action': 'add', 'data': employee.toMap()});
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    final index = _employees.indexWhere((e) => e.reg == employee.reg);
    if (index != -1) {
      _employees[index] = employee;
      await _storage.saveEmployees(_employees);
      notifyListeners();

      if (_isOnline && !_isOfflineManual) {
        await _sheets.syncAll(_employees);
      } else {
        await _storage.addToSyncQueue({'action': 'sync_all'});
      }
    }
  }

  Future<void> deleteEmployee(String reg) async {
    _employees.removeWhere((e) => e.reg == reg);
    await _storage.saveEmployees(_employees);
    notifyListeners();

    if (_isOnline && !_isOfflineManual) {
      final success = await _sheets.deleteEmployee(reg);
      if (!success) {
        await _storage.addToSyncQueue({'action': 'delete', 'reg': reg});
      }
    } else {
      await _storage.addToSyncQueue({'action': 'delete', 'reg': reg});
    }
  }

  // --- SYNC PENDING ---

  Future<void> _syncPendingActions() async {
    final queue = await _storage.getSyncQueue();
    if (queue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    bool allSuccess = true;
    for (final item in queue) {
      final action = item['action'];
      bool success = false;

      if (action == 'add') {
        success = await _sheets.addEmployee(Employee.fromMap(item['data']));
      } else if (action == 'delete') {
        success = await _sheets.deleteEmployee(item['reg']);
      } else if (action == 'sync_all') {
        success = await _sheets.syncAll(_employees);
      }

      if (!success) {
        allSuccess = false;
        break; 
      }
    }

    if (allSuccess) {
      await _storage.clearSyncQueue();
      await fetchFromSheets(); // Final refresh
    }

    _isSyncing = false;
    notifyListeners();
  }

  // --- THEME ---

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _storage.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  void toggleOfflineMode() {
    _isOfflineManual = !_isOfflineManual;
    _storage.saveBool('offline_manual', _isOfflineManual);
    if (!_isOfflineManual && _isOnline) {
      _syncPendingActions();
    }
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale == 'ar' ? 'fr' : 'ar';
    _storage.saveString('app_locale', _locale);
    notifyListeners();
  }

  // --- ABSENCE OPERATIONS ---

  Future<void> addAbsence(String reg, Absence absence, {String author = ''}) async {
    final index = _employees.indexWhere((e) => e.reg == reg);
    if (index != -1) {
      final employee = _employees[index];
      _employees[index] = employee.copyWith(absence: absence);
      await _storage.saveEmployees(_employees);
      notifyListeners();

      // إشعار محلي على نفس الجهاز
      final notifId = employee.reg.hashCode.abs() % 10000;
      await showNotification(
        'تسجيل غياب',
        'تم تسجيل غياب لـ ${employee.name} · ${absence.type}',
        id: notifId,
      );

      if (_isOnline && !_isOfflineManual) {
        await _sheets.syncAll(_employees);
        // ── Push collaborative notification to all other devices ──
        await _sheets.pushNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_$reg',
          type: 'absence_added',
          title: 'غياب جديد',
          message: '${employee.name} · ${absence.type}${author.isNotEmpty ? ' ($author)' : ''}',
          author: author,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        await _storage.addToSyncQueue({'action': 'sync_all'});
      }
    }
  }

  Future<void> archiveAbsence(String reg, {String author = ''}) async {
    final index = _employees.indexWhere((e) => e.reg == reg);
    if (index != -1) {
      final employee = _employees[index];
      if (employee.absence != null) {
        final archived = List<Absence>.from(employee.archivedAbsences)..add(employee.absence!);
        _employees[index] = employee.copyWith(absence: null, archivedAbsences: archived);
        await _storage.saveEmployees(_employees);
        notifyListeners();

        if (_isOnline && !_isOfflineManual) {
          await _sheets.syncAll(_employees);
          // ── Push collaborative notification ──
          await _sheets.pushNotification(
            id: '${DateTime.now().millisecondsSinceEpoch}_arch_$reg',
            type: 'absence_archived',
            title: 'أرشفة غياب',
            message: 'تم أرشفة غياب ${employee.name}${author.isNotEmpty ? ' ($author)' : ''}',
            author: author,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
        } else {
          await _storage.addToSyncQueue({'action': 'sync_all'});
        }
      }
    }
  }

  Future<void> removeAbsence(String reg, {String author = ''}) async {
    final index = _employees.indexWhere((e) => e.reg == reg);
    if (index != -1) {
      final employee = _employees[index];
      _employees[index] = employee.copyWith(absence: null);
      await _storage.saveEmployees(_employees);
      notifyListeners();

      if (_isOnline && !_isOfflineManual) {
        await _sheets.syncAll(_employees);
        // ── Push collaborative notification ──
        await _sheets.pushNotification(
          id: '${DateTime.now().millisecondsSinceEpoch}_rm_$reg',
          type: 'absence_removed',
          title: 'إلغاء غياب',
          message: 'تم إلغاء غياب ${employee.name}${author.isNotEmpty ? ' ($author)' : ''}',
          author: author,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
      } else {
        await _storage.addToSyncQueue({'action': 'sync_all'});
      }
    }
  }
  
  Future<void> deleteFromArchive(String reg, int archiveIndex) async {
    final index = _employees.indexWhere((e) => e.reg == reg);
    if (index != -1) {
      final employee = _employees[index];
      final archived = List<Absence>.from(employee.archivedAbsences)..removeAt(archiveIndex);
      _employees[index] = employee.copyWith(archivedAbsences: archived);
      await _storage.saveEmployees(_employees);
      notifyListeners();

      if (_isOnline && !_isOfflineManual) {
        await _sheets.syncAll(_employees);
      } else {
        await _storage.addToSyncQueue({'action': 'sync_all'});
      }
    }
  }

  // --- IMPORT / EXPORT ---

  Future<void> exportData() async {
    final jsonStr = json.encode(_employees.map((e) => e.toMap()).toList());
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/my_slaves_backup.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية للعمال (ملف JSON)');
  }

  Future<void> importData() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      try {
        final List<dynamic> data = json.decode(content);
        _employees = data.map((e) => Employee.fromMap(e)).toList();
        await _storage.saveEmployees(_employees);
        notifyListeners();
        
        if (_isOnline && !_isOfflineManual) {
          await _sheets.syncAll(_employees);
        } else {
          await _storage.addToSyncQueue({'action': 'sync_all'});
        }
      } catch (e) {
        debugPrint('Error importing data: $e');
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
