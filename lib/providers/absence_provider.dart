import 'package:flutter/foundation.dart';
import '../models/absence.dart';

class AbsenceProvider with ChangeNotifier {
  final List<Absence> _absences = [];

  List<Absence> get absences => [..._absences];

  void addAbsence(Absence absence) {
    _absences.add(absence);
    notifyListeners();
  }

  void deleteAbsence(String id) {
    _absences.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void updateStatus(String id, String newStatus) {
    final index = _absences.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _absences[index].status = newStatus;
      notifyListeners();
    }
  }

  List<Absence> filterByStatus(String status) {
    if (status == 'tous') return absences;
    return _absences.where((a) => a.status == status).toList();
  }
}
