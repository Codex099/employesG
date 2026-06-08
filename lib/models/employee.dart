import 'dart:convert';
import 'package:hive/hive.dart';
import 'absence.dart';

part 'employee.g.dart';

@HiveType(typeId: 3)
class Employee extends HiveObject {
  @HiveField(0)
  final String name;       
  @HiveField(1)
  final String reg;        
  @HiveField(2)
  final String phone;      
  @HiveField(3)
  final String address;    
  @HiveField(4)
  final String status;     
  @HiveField(5)
  final String blood;      
  @HiveField(6)
  final String workplace;  
  @HiveField(7)
  final int? children;     
  @HiveField(8)
  final String notes;      
  @HiveField(9)
  final int created;       
  
  // NOTE: In the new architecture, absences are managed in a separate box and sheet.
  // We keep this nullable property if we want to attach an absence locally at runtime,
  // but it's typically ignored for raw serialization.
  @HiveField(10)
  Absence? absence; 

  @HiveField(11)
  final String? deletedAt;

  @HiveField(12)
  final int version;

  @HiveField(13)
  final String updatedAt;

  // We keep archivedAbsences for backward UI compat but its source of truth is now the absences box
  @HiveField(14)
  List<Absence> archivedAbsences = [];

  // Used to mark if this employee is pending a deletion in offline mode
  @HiveField(15)
  bool pendingDelete = false;

  Employee({
    required this.name,
    required this.reg,
    required this.phone,
    required this.address,
    required this.status,
    required this.blood,
    required this.workplace,
    this.children,
    required this.notes,
    required this.created,
    this.absence,
    this.deletedAt,
    this.version = 1,
    required this.updatedAt,
    this.archivedAbsences = const [],
    this.pendingDelete = false,
  });

  static const Object _notSet = Object();

  Employee copyWith({
    String? name,
    String? reg,
    String? phone,
    String? address,
    String? status,
    String? blood,
    String? workplace,
    int? children,
    String? notes,
    int? created,
    Object? absence = _notSet,
    Object? deletedAt = _notSet,
    int? version,
    String? updatedAt,
    List<Absence>? archivedAbsences,
    bool? pendingDelete,
  }) {
    return Employee(
      name: name ?? this.name,
      reg: reg ?? this.reg,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
      blood: blood ?? this.blood,
      workplace: workplace ?? this.workplace,
      children: children ?? this.children,
      notes: notes ?? this.notes,
      created: created ?? this.created,
      absence: identical(absence, _notSet) ? this.absence : absence as Absence?,
      deletedAt: identical(deletedAt, _notSet) ? this.deletedAt : deletedAt as String?,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAbsences: archivedAbsences ?? this.archivedAbsences,
      pendingDelete: pendingDelete ?? this.pendingDelete,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'reg': reg,
      'phone': phone,
      'address': address,
      'status': status,
      'blood': blood,
      'workplace': workplace,
      'children': children ?? '',
      'notes': notes,
      'created': created,
      'deletedAt': deletedAt ?? '',
      'version': version,
      'updatedAt': updatedAt,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    String asString(dynamic val) => val?.toString() ?? '';

    return Employee(
      name: asString(map['name']),
      reg: asString(map['reg']),
      phone: asString(map['phone']),
      address: asString(map['address']),
      status: asString(map['status']),
      blood: asString(map['blood']),
      workplace: asString(map['workplace']),
      children: int.tryParse(map['children']?.toString() ?? ''),
      notes: asString(map['notes']),
      created: int.tryParse(map['created']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      deletedAt: map['deletedAt']?.toString() == '' ? null : map['deletedAt']?.toString(),
      version: int.tryParse(map['version']?.toString() ?? '1') ?? 1,
      updatedAt: asString(map['updatedAt']).isEmpty ? DateTime.now().toIso8601String() : asString(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Employee.fromJson(String source) => Employee.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee && other.reg == reg;
  }

  @override
  int get hashCode => reg.hashCode;
}