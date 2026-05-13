import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import 'sheets_service.dart';

class AuthService extends ChangeNotifier {
  final SheetsService _sheets = SheetsService();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  UserRole get currentRole => _currentUser?.role ?? UserRole.user;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => currentRole == UserRole.admin;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─── Compte Admin par défaut (seed) ───────────────────────────────────────
  // Utilisé uniquement si la feuille "users" est vide.
  // Username: admin   Password: admin123
  static final AppUser _defaultAdmin = AppUser(
    username: 'admin',
    passwordHash: _sha256('admin123'),
    role: UserRole.admin,
    fullName: 'المدير',
    createdAt: 0,
  );

  // ─── Hash ─────────────────────────────────────────────────────────────────
  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ─── Initialisation ───────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('session_user');
    if (saved != null) {
      try {
        _currentUser = AppUser.fromJson(saved);
        notifyListeners();
      } catch (_) {
        await prefs.remove('session_user');
      }
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hash = _sha256(password.trim());
      final users = await _sheets.fetchUsers();
      List<AppUser> allUsers = users ?? [];

      // Injecter l'admin par défaut s'il n'existe pas dans la liste récupérée
      if (!allUsers.any((u) => u.username.toLowerCase() == 'admin')) {
        allUsers.add(_defaultAdmin);
      }

      final match = allUsers.where(
        (u) =>
            u.username.toLowerCase() == username.toLowerCase().trim() &&
            u.passwordHash == hash,
      );

      if (match.isNotEmpty) {
        _currentUser = match.first;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_user', _currentUser!.toJson());
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال، تحقق من الإنترنت';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_user');
    notifyListeners();
  }

  // ─── Gestion des utilisateurs (Admin seulement) ───────────────────────────
  Future<List<AppUser>> fetchAllUsers() async {
    final users = await _sheets.fetchUsers();
    if (users == null || users.isEmpty) return [_defaultAdmin];
    return users;
  }

  Future<bool> createUser({
    required String username,
    required String password,
    required UserRole role,
    required String fullName,
  }) async {
    final user = AppUser(
      username: username.trim(),
      passwordHash: _sha256(password.trim()),
      role: role,
      fullName: fullName.trim(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    return _sheets.addUser(user);
  }

  Future<bool> updateUserPassword({
    required AppUser user,
    required String newPassword,
  }) async {
    final updated = user.copyWith(passwordHash: _sha256(newPassword.trim()));
    return _sheets.updateUser(updated);
  }

  Future<bool> updateUserRole({
    required AppUser user,
    required UserRole newRole,
  }) async {
    final updated = user.copyWith(role: newRole);
    return _sheets.updateUser(updated);
  }

  Future<bool> updateUser(AppUser user) async {
    return _sheets.updateUser(user);
  }

  Future<bool> deleteUser(String username) async {
    return _sheets.deleteUser(username);
  }

  /// Hash public pour la création depuis l'extérieur
  static String hashPassword(String password) => _sha256(password.trim());
}
