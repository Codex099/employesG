import 'package:hive/hive.dart';

part 'pending_action.g.dart';

@HiveType(typeId: 2)
class PendingAction extends HiveObject {
  @HiveField(0)
  final String action; // e.g. 'delete', 'create', 'update'

  @HiveField(1)
  final String entityType; // e.g. 'employee', 'absence'

  @HiveField(2)
  final String entityId;

  @HiveField(3)
  final Map<String, dynamic>? payload;

  @HiveField(4)
  final DateTime timestamp;

  PendingAction({
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    this.payload,
  });
}
