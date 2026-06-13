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
import '../models/public_note.dart';
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
  late final Box<PublicNote> _notesBox;

  final isSyncing = false.obs;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    _employeesBox = Hive.box<Employee>('employees');
    _absencesBox = Hive.box<Absence>('absences');
    _workplacesBox = Hive.box<Workplace>('workplaces');
    _notesBox = Hive.box<PublicNote>('public_notes');

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
  List<PublicNote> get notes => _notesBox.values.where((n) => n.deletedAt == null).toList();

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
    // Rebuild UI immediately to show manual state change
    update();
    
    Get.find<ConnectivityService>().toggleForceOffline().then((_) {
      if (isOnline) {
        _queue.flush();
      }
      // Rebuild again after connectivity check finishes
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
    await _pullNotes();
    await _settingsBox.put('lastSyncTimestamp', DateTime.now().toUtc().toIso8601String());
  }


  Future<void> _pullEmployees() async {
    final list = await _sheets.fetchEmployees();
    if (list != null) {
      final remoteRegs = list.map((e) => e.reg).toSet();
      
      // 1. Clean up local records that are missing from the server
      final pendingRegs = _queue.actions
          .where((a) => a.entityType == 'employee')
          .map((a) => a.entityId)
          .toSet();

      for (final localReg in _employeesBox.keys.toList()) {
        if (!remoteRegs.contains(localReg) && !pendingRegs.contains(localReg)) {
          await _employeesBox.delete(localReg);
        }
      }

      // 2. Update/Add from server
      for (final remote in list) {
        final local = _employeesBox.get(remote.reg);
        
        if (remote.deletedAt != null) {
          if (local != null) await _employeesBox.delete(remote.reg);
        } else {
          if (local != null && local.pendingDelete) continue;
          if (local == null || remote.version >= local.version) {
             await _employeesBox.put(remote.reg, remote);
          }
        }
      }
    }
  }

  Future<void> _pullAbsences() async {
    final list = await _sheets.fetchAbsences();
    if (list != null) {
      final remoteIds = list.map((a) => a.id).toSet();
      final pendingIds = _queue.actions
          .where((a) => a.entityType == 'absence')
          .map((a) => a.entityId)
          .toSet();

      for (final localId in _absencesBox.keys.toList()) {
        if (!remoteIds.contains(localId) && !pendingIds.contains(localId)) {
          await _absencesBox.delete(localId);
        }
      }

      for (final remote in list) {
        final local = _absencesBox.get(remote.id);
        if (remote.deletedAt != null) {
          if (local != null) await _absencesBox.delete(remote.id);
        } else {
          if (local == null || remote.version >= local.version) {
            await _absencesBox.put(remote.id, remote);
          }
        }
      }
    }
  }

  Future<void> _pullWorkplaces() async {
    final list = await _sheets.fetchWorkplaces();
    if (list != null) {
      final remoteIds = list.map((w) => w.id).toSet();
      final pendingIds = _queue.actions
          .where((a) => a.entityType == 'workplace')
          .map((a) => a.entityId)
          .toSet();

      for (final localId in _workplacesBox.keys.toList()) {
        if (!remoteIds.contains(localId) && !pendingIds.contains(localId)) {
          await _workplacesBox.delete(localId);
        }
      }

      for (final remote in list) {
        final local = _workplacesBox.get(remote.id);
        if (remote.deletedAt != null) {
          if (local != null) await _workplacesBox.delete(remote.id);
        } else {
          if (local == null || remote.version >= local.version) {
            await _workplacesBox.put(remote.id, remote);
          }
        }
      }
    }
  }

  Future<void> _pullNotes() async {
    final list = await _sheets.fetchNotes();
    if (list != null) {
      final remoteIds = list.map((n) => n['id'].toString()).toSet();
      final pendingIds = _queue.actions
          .where((a) => a.entityType == 'public_note')
          .map((a) => a.entityId)
          .toSet();

      for (final localId in _notesBox.keys.toList()) {
        if (!remoteIds.contains(localId) && !pendingIds.contains(localId)) {
          await _notesBox.delete(localId);
        }
      }

      for (final map in list) {
        final remote = PublicNote.fromMap(map);
        final local = _notesBox.get(remote.id);
        if (remote.deletedAt != null) {
          if (local != null) await _notesBox.delete(remote.id);
        } else {
          if (local == null || remote.version >= local.version) {
            await _notesBox.put(remote.id, remote);
          }
        }
      }
    }
  }

  // --- UI CRUD Actions ---

  Future<void> addEmployee(Employee emp) async {
    await _employeesBox.put(emp.reg, emp);
    update();
    
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
    
    _sheets.addEmployeeRaw(emp.toMap()).then((success) {
      if (!success) {
        _queue.enqueue(PendingAction(
          action: 'add_employee',
          entityType: 'employee',
          entityId: emp.reg,
          payload: emp.toMap(),
          timestamp: DateTime.now().toUtc(),
        ));
      } else {
        fetchFromSheets();
      }
    });
  }

  Future<void> updateEmployee(Employee emp) async {
    await _employeesBox.put(emp.reg, emp);
    update();

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
    
    _sheets.updateEmployeeRaw(emp.reg, emp.toMap()).then((success) {
      if (!success) {
        _queue.enqueue(PendingAction(
          action: 'update_employee',
          entityType: 'employee',
          entityId: emp.reg,
          payload: emp.toMap(),
          timestamp: DateTime.now().toUtc(),
        ));
      } else {
        fetchFromSheets();
      }
    });
  }

  Future<void> deleteEmployee(String reg) async {
    final emp = _employeesBox.get(reg);
    if (emp != null) {
      emp.pendingDelete = true;
      await _employeesBox.put(reg, emp);
      update();
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
    
    _sheets.deleteEmployee(reg).then((success) {
      if (!success) {
        _queue.enqueue(PendingAction(
          action: 'delete_employee',
          entityType: 'employee',
          entityId: reg,
          timestamp: DateTime.now().toUtc(),
        ));
      } else {
        _employeesBox.delete(reg);
        fetchFromSheets();
      }
    });
  }

  // --- Absences ---

  Future<void> addAbsence(String reg, Absence absence, {String author = ''}) async {
    // 1. Update local DB
    await _absencesBox.put(absence.id, absence);
    
    final emp = _employeesBox.get(reg);
    if (emp != null) {
      emp.absence = absence;
      await _employeesBox.put(reg, emp);
      update();
    }

    // 2. Sync to backend
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

    _sheets.addAbsenceRaw(absence.toMap()).then((success) {
      if (!success) {
        _queue.enqueue(PendingAction(
          action: 'add_absence',
          entityType: 'absence',
          entityId: absence.id,
          payload: absence.toMap(),
          timestamp: DateTime.now().toUtc(),
        ));
      }
    });
  }

  Future<void> archiveAbsence(String reg, {String author = ''}) async {
    final emp = _employeesBox.get(reg);
    if (emp != null && emp.absence != null) {
      final toArchive = emp.absence!;
      emp.archivedAbsences = List.from(emp.archivedAbsences)..add(toArchive);
      emp.absence = null;
      await updateEmployee(emp);
      update();
    }
  }

  Future<void> deleteFromArchive(String reg, int index) async {
    final emp = _employeesBox.get(reg);
    if (emp != null && index >= 0 && index < emp.archivedAbsences.length) {
      final list = List<Absence>.from(emp.archivedAbsences);
      list.removeAt(index);
      emp.archivedAbsences = list;
      await updateEmployee(emp);
      update();
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
      update();
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
  // --- Public Notes ---

  Future<void> addNote(PublicNote note) async {
    await _notesBox.put(note.id, note);
    update();

    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'add_note',
        entityType: 'public_note',
        entityId: note.id,
        payload: note.toMap(),
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }

    _sheets.addNoteRaw(note.toMap()).then((success) {
      if (!success) {
        _queue.enqueue(PendingAction(
          action: 'add_note',
          entityType: 'public_note',
          entityId: note.id,
          payload: note.toMap(),
          timestamp: DateTime.now().toUtc(),
        ));
      }
    });
  }

  Future<void> updateNote(PublicNote note) async {
    await _notesBox.put(note.id, note);
    update();

    if (!ConnectivityService.isConnected) {
      await _queue.enqueue(PendingAction(
        action: 'update_note',
        entityType: 'public_note',
        entityId: note.id,
        payload: note.toMap(),
        timestamp: DateTime.now().toUtc(),
      ));
      return;
    }

    _sheets.updateNoteRaw(note.id, note.toMap()).then((success) {
      if (!success) {
        _queue.enqueue(PendingAction(
          action: 'update_note',
          entityType: 'public_note',
          entityId: note.id,
          payload: note.toMap(),
          timestamp: DateTime.now().toUtc(),
        ));
      }
    });
  }

  Future<void> deleteNote(String id) async {
    final note = _notesBox.get(id);
    if (note != null) {
      await _notesBox.delete(id);
      update();

      if (!ConnectivityService.isConnected) {
        await _queue.enqueue(PendingAction(
          action: 'delete_note',
          entityType: 'public_note',
          entityId: id,
          timestamp: DateTime.now().toUtc(),
        ));
        return;
      }

      _sheets.deleteNote(id).then((success) {
        if (!success) {
          _queue.enqueue(PendingAction(
            action: 'delete_note',
            entityType: 'public_note',
            entityId: id,
            timestamp: DateTime.now().toUtc(),
          ));
        }
      });
    }
  }
}
