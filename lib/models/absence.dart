import 'dart:convert';
import 'package:hive/hive.dart';

part 'absence.g.dart';

@HiveType(typeId: 0)
enum AbsenceType {
  @HiveField(0)
  congeAnnuel,    // عطلة سنوية
  
  @HiveField(1)
  congeMaternite, // غ غ ش
  
  @HiveField(2)
  maladie,        // مرض
  
  @HiveField(3)
  sanssolde,      // بدون راتب
  
  @HiveField(4)
  autre,          // autre
}

@HiveType(typeId: 1)
class Absence extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String employeeId;
  
  @HiveField(2)
  final String typeString; // Keep it string for easy serialization with Apps Script, or convert from Enum
  
  @HiveField(3)
  final String startDate; // Keep original formatting
  
  @HiveField(4)
  final String endDate;
  
  @HiveField(5)
  final String? note;
  
  @HiveField(6)
  final String? deletedAt;
  
  @HiveField(7)
  final int version;
  
  @HiveField(8)
  final String updatedAt;

  // Additional fields for backward compat or UI
  @HiveField(9)
  final int? days;
  @HiveField(10)
  final String? returnDate;

  String get type => typeString;
  String get date => updatedAt; // date is missing from constructor, defaulting to updatedAt or startDate
  String? get reason => note;

  Absence({
    required this.id,
    required this.employeeId,
    required this.typeString,
    required this.startDate,
    required this.endDate,
    this.note,
    this.deletedAt,
    this.version = 1,
    required this.updatedAt,
    this.days,
    this.returnDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'type': typeString,
      'startDate': startDate,
      'endDate': endDate,
      'note': note ?? '',
      'deletedAt': deletedAt ?? '',
      'version': version,
      'updatedAt': updatedAt,
      'days': days ?? '',
      'returnDate': returnDate ?? '',
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      id: map['id']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      typeString: map['type']?.toString() ?? '',
      startDate: map['startDate']?.toString() ?? '',
      endDate: map['endDate']?.toString() ?? '',
      note: map['note'],
      deletedAt: map['deletedAt']?.toString() == '' ? null : map['deletedAt'],
      version: int.tryParse(map['version']?.toString() ?? '1') ?? 1,
      updatedAt: map['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      days: int.tryParse(map['days']?.toString() ?? ''),
      returnDate: map['returnDate'],
    );
  }

  String toJson() => json.encode(toMap());
  factory Absence.fromJson(String source) => Absence.fromMap(json.decode(source));
}
