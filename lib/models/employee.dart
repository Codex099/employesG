import 'dart:convert';
import 'absence.dart';


class Employee {
  final String name;       // nom complet
  final String reg;        // matricule (identifiant unique)
  final String phone;      // téléphone
  final String address;    // adresse
  final String status;     // situation : متزوج | أعزب | مطلق | أرمل | ""
  final String blood;      // groupe sanguin : A+ A- B+ B- O+ O- AB+ AB- | ""
  final String workplace;  // lieu de travail
  final int? children;     // nombre d'enfants (nullable)
  final String notes;      // notes libres
  final int created;       // timestamp ms
  final Absence? absence;  // Absence actuelle
  final List<Absence> archivedAbsences; // Historique des absences archivées

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
    this.archivedAbsences = const [],
  });

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
    Absence? absence,
    List<Absence>? archivedAbsences,
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
      absence: absence ?? this.absence,
      archivedAbsences: archivedAbsences ?? this.archivedAbsences,
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
      'children': children,
      'notes': notes,
      'created': created,
      'absence': absence != null ? jsonEncode(absence!.toMap()) : '',
      'archivedAbsences': jsonEncode(archivedAbsences.map((x) => x.toMap()).toList()),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    // Helper to ensure values are strings (Google Sheets often returns numbers for phone/reg)
    String asString(dynamic val) => val?.toString() ?? '';

    return Employee(
      name: asString(map['name']),
      reg: asString(map['reg']),
      phone: asString(map['phone']),
      address: asString(map['address']),
      status: asString(map['status']),
      blood: asString(map['blood']),
      workplace: asString(map['workplace']),
      children: map['children'] != null ? int.tryParse(map['children'].toString()) : null,
      notes: asString(map['notes']),
      created: map['created'] is int ? map['created'] : (int.tryParse(map['created'].toString()) ?? DateTime.now().millisecondsSinceEpoch),
      absence: () {
        final abs = map['absence'];
        if (abs == null || abs == '') return null;
        if (abs is String) {
          try { return Absence.fromMap(jsonDecode(abs)); } catch(_) { return null; }
        }
        if (abs is Map<String, dynamic>) return Absence.fromMap(abs);
        return null;
      }(),
      archivedAbsences: () {
        final arch = map['archivedAbsences'];
        if (arch == null || arch == '') return const <Absence>[];
        if (arch is String) {
          try {
            final List<dynamic> decoded = jsonDecode(arch);
            return decoded.map((x) => Absence.fromMap(x)).toList();
          } catch(_) { return const <Absence>[]; }
        }
        if (arch is List) {
          return arch.map((x) => Absence.fromMap(x)).toList();
        }
        return const <Absence>[];
      }(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Employee.fromJson(String source) => Employee.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is Employee &&
      other.reg == reg;
  }

  @override
  int get hashCode => reg.hashCode;
}