import 'package:hive/hive.dart';

part 'employee.g.dart';

@HiveType(typeId: 0)
class Employee extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String reg;

  @HiveField(2)
  String? phone;

  @HiveField(3)
  String? address;

  @HiveField(4)
  String? status;

  @HiveField(5)
  String? blood;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  DateTime created;

  Employee({
    required this.name,
    required this.reg,
    this.phone,
    this.address,
    this.status,
    this.blood,
    this.notes,
    DateTime? created,
  }) : created = created ?? DateTime.now();

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').take(2).join();
  }
}