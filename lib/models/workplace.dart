import 'package:hive/hive.dart';

part 'workplace.g.dart';

@HiveType(typeId: 5)
class Workplace extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? deletedAt;
  
  @HiveField(3)
  final int version;
  
  @HiveField(4)
  final String updatedAt;

  Workplace({
    required this.id,
    required this.name,
    this.deletedAt,
    this.version = 1,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'deletedAt': deletedAt,
      'version': version,
      'updatedAt': updatedAt,
    };
  }

  factory Workplace.fromMap(Map<dynamic, dynamic> map) {
    return Workplace(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      deletedAt: map['deletedAt']?.toString() == '' ? null : map['deletedAt']?.toString(),
      version: int.tryParse(map['version']?.toString() ?? '1') ?? 1,
      updatedAt: map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}
