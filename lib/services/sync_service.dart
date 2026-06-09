import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/employee.dart';
import '../models/absence.dart';
import '../models/workplace.dart';
import 'sheets_service.dart';
import 'connectivity_service.dart';
import 'pending_queue_service.dart';
import '../models/pending_action.dart';

class SyncService extends GetxController {
  final _sheets = Get.find<SheetsService>();
  final _queue = Get.find<PendingQueueService>();
  final _settingsBox = Hive.box('settings');
  late final Box<Employee> _employeesBox;
  late final Box<Absence> _absencesBox;
  late final Box<Workplace> _workplacesBox;

  final isSyncing = false.obs;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    _employeesBox = Hive.box<Employee>('employees');
    _absencesBox = Hive.box<Absence>('absences');
    _workplacesBox = Hive.box<Workplace>('workplaces');

    // Auto sync when online status changes
    ever(Get.find<ConnectivityService>().isOnline, (bool online) {
      if (online && !isOfflineManual) {
        fetchFromSheets();
      }
    });

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isOnline) {
        fetchFromSheets();
      }
    });

    _startPolling();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isOnline) {
        syncIfNeeded(force: false);
      }
    });
  }

  List<Employee> get employees => _employeesBox.values.where((e) => e.deletedAt == null && !e.pendingDelete).toList();
  List<Workplace> get workplaces => _workplacesBox.values.where((w) => w.deletedAt == null).toList();

  List<Absence> get absences => _absencesBox.values.where((a) => a.deletedAt == null).toList();

  bool get isDarkMode => _settingsBox.get('isDarkMode', defaultValue: false);
  String get locale => _settingsBox.get('locale', defaultValue: 'ar');
  bool get isOfflineManual => Get.find<ConnectivityService>().isForceOffline.value;
  bool get isOnline => ConnectivityService.isConnected && !isOfflineManual;

  void toggleTheme() {
    _settingsBox.put('isDarkMode', !isDarkMode);
    update();
  }

  void toggleLanguage() {
    final cur = _settingsBox.get('language', defaultValue: 'ar') as String;
    _settingsBox.put('language', cur == 'ar' ? 'fr' : 'ar');
    update();
  }

  void toggleOfflineMode() {
    Get.find<ConnectivityService>().toggleForceOffline().then((_) {
      if (isOnline) {
        _queue.flush();
      }
      update();
    });
  }

  /// Manual refresh — sets isSyncing immediately so button disables on first click.
  Future<void> fetchFromSheets() async {
    if (isSyncing.value || !isOnline) return; // guard double-click
    isSyncing.value = true;
    update(); // spinner shows immediately
    try {
      await _silentPull();
    } finally {
      isSyncing.value = false;
      update(); // spinner hides
    }
  }

  /// Background / post-CRUD silent check — no spinner shown.
  Future<void> syncIfNeeded({bool force = false}) async {
    if (!isOnline || isSyncing.value) return;

    final remoteTs = await _sheets.fetchConfigLastModified();
    if (remoteTs == null) return;

    final localTsStr = _settingsBox.get('lastSyncTimestamp');

    bool needsPull = force;
    if (!needsPull && localTsStr != null) {
      try {
        final localTs = DateTime.parse(localTsStr);
        final remoteDate = DateTime.parse(remoteTs);
        if (remoteDate.isAfter(localTs)) {
          needsPull = true;
        }
      } catch (_) {
        needsPull = true;
      }
    }

    if (needsPull) {
      await _silentPull();
      update();
    }
  }

  /// Pull all data from Sheets and update local timestamp. No spinner management.
  Future<void> _silentPull() async {
    await _pullEmployees();
    await _pullAbsences();
    await _pullWorkplaces();
    await _settingsBox.put('lastSyncTimestamp', DateTime.now().toUtc().toIso8601String());
  }


  Future<void> _pullEmployees() async {
    final list = await _sheets.fetchEmployees();
    if (list != null) {
      for (final e in list) {
        if (e.deletedAt != null) {
          if (_employeesBox.containsKey(e.reg)) await _employeesBox.delete(e.reg);
        } else {
          e.pendingDelete = false; // reset flag
          await _employeesBox.put(e.reg, e);
        }
      }
    }
  }

  Future<void> _pullAbsences() async {
    final list = await _sheets.fetchAbsences();
    if (list != null) {
      for (final a in list) {
        if (a.deletedAt != null) {
          if (_absencesBox.containsKey(a.id)) await _absencesBox.delete(a.id);
        } else {
          await _absencesBox.put(a.id, a);
        }
      }
    }
  }

  Future<void> _pullWorkplaces() async {
    final list = await _sheets.fetchWorkplaces();
    if (list != null) {
      for (final w in list) {
        if (w.deletedAt != null) {
          if (_workplacesBox.containsKey(w.id)) await _workplacesBox.delete(w.id);
        } else {
          await _workplacesBox.put(w.id, w);
        }
      }
    }
  }

  // --- UI CRUD Actions ---

  Future<void> addEmployee(Employee emp) async {
    await _employeesBox.put(emp.reg, emp);
    
    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'add_employee',
        entityType: 'employee',
        entityId: emp.reg,
        payload: emp.toMap(),
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }
    
    await _sheets.addEmployeeRaw(emp.toMap());
    await fetchFromSheets();
  }

  Future<void> updateEmployee(Employee emp) async {
    await _employeesBox.put(emp.reg, emp);

    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'update_employee',
        entityType: 'employee',
        entityId: emp.reg,
        payload: emp.toMap(),
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }
    
    await _sheets.updateEmployeeRaw(emp.reg, emp.toMap());
    await fetchFromSheets();
  }

  Future<void> deleteEmployee(String reg) async {
    final emp = _employeesBox.get(reg);
    if (emp != null) {
      emp.pendingDelete = true;
      await _employeesBox.put(reg, emp);
    }

    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'delete_employee',
        entityType: 'employee',
        entityId: reg,
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }
    
    await _sheets.deleteEmployee(reg);
    await _employeesBox.delete(reg);
    await fetchFromSheets();
  }

  // --- Absences ---

  Future<void> addAbsence(String reg, Absence absence, {String author = ''}) async {
    // Audit log
    await _absencesBox.put(absence.id, absence);
    if (ConnectivityService.isConnected) {
      _sheets.addAbsenceRaw(absence.toMap());
    }

    final emp = _employeesBox.get(reg);
    if (emp != null) {
      emp.absence = absence;
      await updateEmployee(emp);
    }
  }

  Future<void> archiveAbsence(String reg, {String author = ''}) async {
    final emp = _employeesBox.get(reg);
    if (emp != null && emp.absence != null) {
      final toArchive = emp.absence!;
      emp.archivedAbsences = List.from(emp.archivedAbsences)..add(toArchive);
      emp.absence = null;
      await updateEmployee(emp);
    }
  }

  Future<void> deleteFromArchive(String reg, int index) async {
    final emp = _employeesBox.get(reg);
    if (emp != null && index >= 0 && index < emp.archivedAbsences.length) {
      final list = List<Absence>.from(emp.archivedAbsences);
      list.removeAt(index);
      emp.archivedAbsences = list;
      await updateEmployee(emp);
    }
  }

  Future<void> exportData() async {
    try {
      final data = {
        'employees': _employeesBox.values.map((e) => e.toMap()).toList(),
        'workplaces': _workplacesBox.values.map((w) => w.toMap()).toList(),
      };
      
      final jsonStr = jsonEncode(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/geem_backup.json');
      await file.writeAsString(jsonStr);
      
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'Geem Backup',
      ));
    } catch (e) {
      Get.snackbar('Error', 'file_error'.tr, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> importData() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final data = jsonDecode(jsonStr);

        if (data['employees'] != null) {
          final List emps = data['employees'];
          for (var eMap in emps) {
            final emp = Employee.fromMap(eMap);
            await updateEmployee(emp); // Push to local DB and enqueue for backend
          }
        }
        if (data['workplaces'] != null) {
          final List wps = data['workplaces'];
          for (var wMap in wps) {
            final wp = Workplace.fromMap(wMap);
            await addWorkplace(wp);
          }
        }
        Get.snackbar('Success', 'import_success'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFF4ade80), colorText: const Color(0xFFFFFFFF));
      }
    } catch (e) {
      Get.snackbar('Error', 'file_error'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: const Color(0xFFef4444), colorText: const Color(0xFFFFFFFF));
    }
  }

  Future<void> removeAbsence(String reg, {String author = ''}) async {
    final emp = _employeesBox.get(reg);
    if (emp != null) {
      emp.absence = null;
      await updateEmployee(emp);
    }
  }

  // --- Workplaces ---

  Future<void> addWorkplace(Workplace wp) async {
    await _workplacesBox.put(wp.id, wp);
    update();

    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'add_workplace',
        entityType: 'workplace',
        entityId: wp.id,
        payload: wp.toMap(),
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }
    
    // Push to backend asynchronously — don't block UI
    _sheets.addWorkplaceRaw(wp.toMap()).then((success) {
      if (!success) {
        // Queue for retry if backend push failed
        _queue.enqueue(PendingAction(
          action: 'add_workplace',
          entityType: 'workplace',
          entityId: wp.id,
          payload: wp.toMap(),
          timestamp: DateTime.now().toUtc(),
        ));
      }
    });
  }

  Future<void> deleteWorkplace(String id) async {
    final wp = _workplacesBox.get(id);
    if (wp != null) {
      await _workplacesBox.delete(id);
      update(); // Refresh GetBuilder immediately

      if (!ConnectivityService.isConnected) {
        await _queue.enqueue(PendingAction(
          action: 'delete_workplace',
          entityType: 'workplace',
          entityId: id,
          timestamp: DateTime.now().toUtc(),
        ));
        return;
      }
      
      // Push to backend asynchronously
      _sheets.deleteWorkplace(id).then((success) {
        if (!success) {
          _queue.enqueue(PendingAction(
            action: 'delete_workplace',
            entityType: 'workplace',
            entityId: id,
            timestamp: DateTime.now().toUtc(),
          ));
        }
      });
    }
  }
}
