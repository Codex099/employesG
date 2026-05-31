enum UserRole { admin, manager, user }

extension UserRoleExtension on UserRole {
  /// Peut supprimer un employé
  bool get canDelete => this == UserRole.admin;

  /// Peut ajouter un employé
  bool get canAdd => this == UserRole.admin || this == UserRole.manager;

  /// Peut modifier un employé
  bool get canEdit => this == UserRole.admin || this == UserRole.manager;

  /// Peut marquer une absence (ajouter)
  bool get canMarkAbsence => this == UserRole.admin || this == UserRole.manager;

  /// Peut archiver/supprimer une absence — ADMIN uniquement
  bool get canManageAbsence => this == UserRole.admin;

  /// Peut gérer les comptes utilisateurs de l'app
  bool get canManageUsers => this == UserRole.admin;

  /// Peut importer / exporter les données
  bool get canImportExport => this == UserRole.admin;

  /// Label affichable
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'مدير النظام';
      case UserRole.manager:
        return 'مشرف';
      case UserRole.user:
        return 'مستخدم';
    }
  }

  /// Couleur associée au rôle
  String get colorHex {
    switch (this) {
      case UserRole.admin:
        return '#ef4444'; // rouge
      case UserRole.manager:
        return '#f59e0b'; // orange
      case UserRole.user:
        return '#10b981'; // vert
    }
  }

  static UserRole fromString(String s) {
    switch (s.toLowerCase().trim()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.user;
    }
  }

  String toSheetValue() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.user:
        return 'user';
    }
  }
}
