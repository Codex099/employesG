class Conge {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String motif;
  String status; // en_attente, approuvé, refusé, terminé

  Conge({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.dateDebut,
    required this.dateFin,
    required this.motif,
    this.status = 'en_attente',
  });

  int get nombreJours {
    // Calcul simple : différence en jours + 1 (pour inclure le dernier jour)
    return dateFin.difference(dateDebut).inDays + 1;
  }
}
