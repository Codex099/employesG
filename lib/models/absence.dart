class Absence {
  final String id;
  final String employeeId;
  final String employeeName;
  final String type; // maladie, personnel, autre
  final DateTime date;
  final String justification;
  String status; // en_attente, approuvé, refusé

  Absence({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.date,
    required this.justification,
    this.status = 'en_attente',
  });
}
