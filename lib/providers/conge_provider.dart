import 'package:flutter/foundation.dart';
import '../models/conge.dart';
import '../services/notification_service.dart';

class CongeProvider with ChangeNotifier {
  final List<Conge> _conges = [];
  final NotificationService _notificationService = NotificationService();

  List<Conge> get conges => [..._conges];

  List<Conge> get congesEnAttente =>
      _conges.where((c) => c.status == 'en_attente').toList();

  List<Conge> get congesApprouves =>
      _conges.where((c) => c.status == 'approuvé').toList();

  List<Conge> get historiqueConges =>
      _conges.where((c) => c.status == 'terminé' || c.status == 'refusé').toList();

  void demanderConge(Conge conge) {
    _conges.add(conge);
    notifyListeners();
  }

  void annulerConge(String id) {
    _conges.removeWhere((c) => c.id == id);
    _notificationService.cancelNotification(id.hashCode);
    notifyListeners();
  }

  void approuverConge(String id) {
    final index = _conges.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _conges[index].status = 'approuvé';
      _notificationService.scheduleCongeEndNotification(_conges[index]);
      notifyListeners();
    }
  }

  void refuserConge(String id) {
    final index = _conges.indexWhere((c) => c.id == id);
    if (index >= 0) {
      _conges[index].status = 'refusé';
      _notificationService.cancelNotification(id.hashCode);
      notifyListeners();
    }
  }
}
