import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/pending_action.dart';
import 'sheets_service.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';

class PendingQueueService extends GetxService {
  late final Box<PendingAction> _box;

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box<PendingAction>('pendingQueue');
  }

  Future<void> enqueue(PendingAction action) async {
    await _box.add(action);
  }

  Future<void> flush() async {
    if (_box.isEmpty) return;
    if (!ConnectivityService.isConnected) return;

    final actions = _box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final sheets = Get.find<SheetsService>();

    for (final action in actions) {
      try {
         await _executeAction(action, sheets);
         await action.delete(); // Removes from Hive
      } catch (e) {
         debugPrint('PendingQueue error: $e');
         break; // Stop flushing to maintain order
      }
    }

    // Refresh data using Pull
    await Get.find<SyncService>().syncIfNeeded(force: true);
  }

  Future<void> _executeAction(PendingAction action, SheetsService sheets) async {
    bool success = false;
    switch (action.action) {
      case 'delete_employee':
        success = await sheets.deleteEmployee(action.entityId);
        break;
      case 'add_employee':
        success = await sheets.addEmployeeRaw(action.payload!);
        break;
      case 'update_employee':
        success = await sheets.updateEmployeeRaw(action.entityId, action.payload!);
        break;
      case 'add_absence':
        success = await sheets.addAbsenceRaw(action.payload!);
        break;
      case 'update_absence':
        success = await sheets.updateAbsenceRaw(action.entityId, action.payload!);
        break;
      case 'delete_absence':
        success = await sheets.deleteAbsence(action.entityId);
        break;
    }
    if (!success) {
      throw Exception('Failed action: ${action.action}');
    }
  }
}
