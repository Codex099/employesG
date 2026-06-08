import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/employee.dart';
import '../models/absence.dart';
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

  final isSyncing = false.obs;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    _employeesBox = Hive.box<Employee>('employees');
    _absencesBox = Hive.box<Absence>('absences');

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
    _settingsBox.put('locale', locale == 'ar' ? 'fr' : 'ar');
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
    await _absencesBox.put(absence.id, absence);
    
    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'add_absence',
        entityType: 'absence',
        entityId: absence.id,
        payload: absence.toMap(),
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }
    
    await _sheets.addAbsenceRaw(absence.toMap());
    await fetchFromSheets();
  }

  Future<void> archiveAbsence(String reg, {String author = ''}) async {
    // Soft-delete could act as an archive
  }

  Future<void> deleteFromArchive(String reg, int index) async {
    // Provide backwards compatibility signature.
    // Ideally this maps to removeAbsence if an ID is present.
  }

  Future<void> exportData() async {}
  Future<void> importData() async {}

  Future<void> removeAbsence(String absenceId, {String author = ''}) async {
    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'delete_absence',
        entityType: 'absence',
        entityId: absenceId,
        timestamp: DateTime.now().toUtc(),
      ));
      // Mark locally
      final abs = _absencesBox.get(absenceId);
      if (abs != null) {
         await _absencesBox.delete(absenceId);
      }
      return;
    }
    
    await _sheets.deleteAbsence(absenceId);
    await _absencesBox.delete(absenceId);
    await fetchFromSheets();
  }
}
