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

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;
  final Connectivity _connectivity = Connectivity();

  SyncService() {
    _init();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(settings: const InitializationSettings(android: android, iOS: ios));
  }

  Future<void> showNotification(String title, String body) async {
    const android = AndroidNotificationDetails('absences_channel', 'Absences', importance: Importance.max, priority: Priority.high);
    const ios = DarwinNotificationDetails();
    await _notifications.show(id: 0, title: title, body: body, notificationDetails: const NotificationDetails(android: android, iOS: ios));
  }

  Future<void> _init() async {
    // 1. Load local data and theme immediately
    _employees = await _storage.loadEmployees();
    _isDarkMode = await _storage.loadThemeMode();
    _isOfflineManual = await _storage.loadBool('offline_manual');
    notifyListeners();

    // 2. Monitor connectivity
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _syncPendingActions();
      }
      notifyListeners();
    });

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // 3. Start polling every 10 seconds
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isOnline && !_isSyncing && !_isOfflineManual) {
        await fetchFromSheets();
      }
    });
  }

  Future<void> fetchFromSheets() async {
    // Prevent overwriting local changes if we haven't synced them yet
    final queue = await _storage.getSyncQueue();
    if (queue.isNotEmpty) return;

    _isSyncing = true;
    notifyListeners();

    final remoteEmployees = await _sheets.fetchAll();
    if (remoteEmployees.isNotEmpty) {
      // Simple strategy: remote wins unless we have pending local changes
      // In this specific app, we'll replace local with remote
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

  // --- ABSENCE OPERATIONS ---

  Future<void> addAbsence(String reg, Absence absence) async {
    final index = _employees.indexWhere((e) => e.reg == reg);
    if (index != -1) {
      final employee = _employees[index];
      _employees[index] = employee.copyWith(absence: absence);
      await _storage.saveEmployees(_employees);
      notifyListeners();
      
      showNotification('تسجيل غياب', 'تم تسجيل غياب لـ ${employee.name}');

      if (_isOnline && !_isOfflineManual) {
        await _sheets.syncAll(_employees);
      } else {
        await _storage.addToSyncQueue({'action': 'sync_all'});
      }
    }
  }

  Future<void> archiveAbsence(String reg) async {
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
        } else {
          await _storage.addToSyncQueue({'action': 'sync_all'});
        }
      }
    }
  }

  Future<void> removeAbsence(String reg) async {
    final index = _employees.indexWhere((e) => e.reg == reg);
    if (index != -1) {
      _employees[index] = _employees[index].copyWith(absence: null);
      await _storage.saveEmployees(_employees);
      notifyListeners();

      if (_isOnline && !_isOfflineManual) {
        await _sheets.syncAll(_employees);
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
