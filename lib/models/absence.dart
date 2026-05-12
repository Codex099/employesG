import 'dart:convert';

class Absence {
  final String type;      // غ غ ش | عطلة سنوية | مرض | ...
  final String date;      // date de l'enregistrement
  final String? startDate;
  final int? days;
  final String? returnDate;

  Absence({
    required this.type,
    required this.date,
    this.startDate,
    this.days,
    this.returnDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': date,
      'startDate': startDate,
      'days': days,
      'returnDate': returnDate,
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      type: map['type'] ?? '',
      date: map['date'] ?? '',
      startDate: map['startDate'],
      days: map['days']?.toInt(),
      returnDate: map['returnDate'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Absence.fromJson(String source) => Absence.fromMap(json.decode(source));
}
