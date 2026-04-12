import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  bool _isFrench = false;
  
  bool get isFrench => _isFrench;

  void toggleLanguage() {
    _isFrench = !_isFrench;
    notifyListeners();
  }

  /// Fonction utilitaire de traduction rapide
  String t(String ar, String fr) {
    return _isFrench ? fr : ar;
  }
}
