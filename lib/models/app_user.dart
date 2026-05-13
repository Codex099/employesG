import 'dart:convert';
import 'user_role.dart';

class AppUser {
  final String username;
  final String passwordHash; // SHA-256 hex string
  final UserRole role;
  final String fullName;
  final int createdAt;

  const AppUser({
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.fullName,
    required this.createdAt,
  });

  AppUser copyWith({
    String? username,
    String? passwordHash,
    UserRole? role,
    String? fullName,
    int? createdAt,
  }) {
    return AppUser(
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'username': username,
        'passwordHash': passwordHash,
        'role': role.toSheetValue(),
        'fullName': fullName,
        'createdAt': createdAt,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    String s(dynamic v) => v?.toString() ?? '';
    return AppUser(
      username: s(map['username']),
      passwordHash: s(map['passwordHash']),
      role: UserRoleExtension.fromString(s(map['role'])),
      fullName: s(map['fullName']),
      createdAt: int.tryParse(s(map['createdAt'])) ??
          DateTime.now().millisecondsSinceEpoch,
    );
  }

  String toJson() => json.encode(toMap());
  factory AppUser.fromJson(String source) =>
      AppUser.fromMap(json.decode(source));
}
