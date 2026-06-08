import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../utils/translations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AppUser> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final users = await auth.fetchAllUsers();
    if (mounted) setState(() { _users = users; _loading = false; });
  }

  // ── Role chip colors ──
  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:   return const Color(0xFFef4444);
      case UserRole.manager: return const Color(0xFFf59e0b);
      case UserRole.user:    return const Color(0xFF10b981);
    }
  }

  // ── Show add/edit dialog ──
  void _showUserDialog({AppUser? existing}) {
    final isDark = Get.find<SyncService>().isDarkMode;
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final fullNameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final passwordCtrl = TextEditingController();
    UserRole selectedRole = existing?.role ?? UserRole.user;
    bool obscure = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131e35) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existing == null ? 'new_user'.tr(context) : 'edit_user'.tr(context),
            style: GoogleFonts.almarai(fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0f172a)),
            textAlign: TextAlign.right,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Full name
                    _dialogField(context, fullNameCtrl, 'full_name'.tr(context),
                        Icons.badge_outlined, isDark,
                        validator: (v) => v!.trim().isEmpty ? 'required'.tr(context) : null),
                    const SizedBox(height: 12),
                    // Username
                    _dialogField(context, usernameCtrl, 'username'.tr(context),
                        Icons.person_outline, isDark,
                        enabled: existing == null,
                        validator: (v) => v!.trim().isEmpty ? 'required'.tr(context) : null),
                    const SizedBox(height: 12),
                    // Password
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      textDirection: TextDirection.ltr,
                      style: GoogleFonts.almarai(
                          color: isDark ? Colors.white : const Color(0xFF0f172a)),
                      decoration: _fieldDecor(
                        context: context,
                        isDark: isDark,
                        label: existing == null
                            ? 'password'.tr(context)
                            : 'password_empty_keep'.tr(context),
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () => setDlg(() => obscure = !obscure),
                        ),
                      ),
                      validator: (v) {
                        if (existing == null && (v == null || v.isEmpty)) {
                          return 'required'.tr(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Role selector
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('role'.tr(context),
                          style: GoogleFonts.almarai(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: UserRole.values.map((r) {
                        final selected = selectedRole == r;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setDlg(() => selectedRole = r),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _roleColor(r).withOpacity(0.15)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : const Color(0xFFf8fafc)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? _roleColor(r)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                r.label,
                                style: GoogleFonts.almarai(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: selected
                                      ? _roleColor(r)
                                      : (isDark ? Colors.white54 : Colors.black45),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('cancel'.tr(context),
                  style: GoogleFonts.almarai(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final auth = context.read<AuthService>();
                bool ok;
                if (existing == null) {
                  ok = await auth.createUser(
                    username: usernameCtrl.text,
                    password: passwordCtrl.text,
                    role: selectedRole,
                    fullName: fullNameCtrl.text,
                  );
                } else {
                  // Update role
                  ok = await auth.updateUserRole(
                      user: existing, newRole: selectedRole);
                  // Update name
                  if (ok) {
                    ok = await auth.updateUser(
                        existing.copyWith(fullName: fullNameCtrl.text));
                  }
                  // Update password if provided
                  if (ok && passwordCtrl.text.isNotEmpty) {
                    ok = await auth.updateUserPassword(
                        user: existing, newPassword: passwordCtrl.text);
                  }
                }
                if (mounted) {
                  Navigator.of(context).pop(); 
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'saved_successfully'.tr(context) + ' ✓' : 'error_occurred'.tr(context),
                        style: GoogleFonts.almarai()),
                    backgroundColor:
                        ok ? const Color(0xFF10b981) : const Color(0xFFef4444),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: Text('save'.tr(context), style: GoogleFonts.almarai()),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AppUser user) {
    final isDark = Get.find<SyncService>().isDarkMode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131e35) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('delete'.tr(context),
            style: GoogleFonts.almarai(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0f172a)),
            textAlign: TextAlign.right),
        content: Text('confirm_delete'.tr(context) + ' "${user.fullName}"؟',
            style: GoogleFonts.almarai(
                color: isDark ? Colors.white70 : Colors.black54),
            textAlign: TextAlign.right),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('cancel'.tr(context), style: GoogleFonts.almarai(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              final auth = context.read<AuthService>();
              final ok = await auth.deleteUser(user.username);
              if (mounted) {
                Navigator.pop(context);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'deleted_successfully'.tr(context) + ' ✓' : 'error_occurred'.tr(context),
                      style: GoogleFonts.almarai()),
                  backgroundColor: ok
                      ? const Color(0xFF10b981)
                      : const Color(0xFFef4444),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Text('delete'.tr(context), style: GoogleFonts.almarai()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<SyncService>().isDarkMode;
    final currentUser = context.watch<AuthService>().currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0b1120) : const Color(0xFFf0f4ff),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF131e35) : Colors.white,
          elevation: 0,
          title: Text('user_management'.tr(context),
              style: GoogleFonts.almarai(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0f172a))),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white70 : Colors.black54, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: _loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.white70 : const Color(0xFF0f172a),
                      ),
                    )
                  : Icon(Icons.refresh_rounded,
                      color: isDark ? Colors.white70 : Colors.black54),
              onPressed: _loading ? null : _loadUsers,
            )
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showUserDialog(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded),
          label: Text('new_user'.tr(context), style: GoogleFonts.almarai()),
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : _users.isEmpty
                ? Center(
                    child: Text('no_users'.tr(context),
                        style: GoogleFonts.almarai(
                            color: isDark ? Colors.white38 : Colors.black26)))
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: Theme.of(context).colorScheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final user = _users[i];
                        final isSelf =
                            user.username == currentUser?.username;
                        return _buildUserCard(context, user, isSelf, isDark);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppUser user, bool isSelf, bool isDark) {
    final color = _roleColor(user.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131e35) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelf
              ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05)),
          width: isSelf ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          radius: 24,
          child: Text(
            user.fullName.isNotEmpty
                ? user.fullName[0].toUpperCase()
                : user.username[0].toUpperCase(),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName.isNotEmpty ? user.fullName : user.username,
                style: GoogleFonts.almarai(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0f172a)),
              ),
            ),
            if (isSelf)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('you'.tr(context),
                    style: GoogleFonts.almarai(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('@${user.username}',
                style: GoogleFonts.almarai(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38)),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(user.role.label,
                  style: GoogleFonts.almarai(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          ],
        ),
        trailing: isSelf
            ? null
            : PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: isDark ? Colors.white38 : Colors.black38),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: isDark ? const Color(0xFF1e2d4a) : Colors.white,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('edit'.tr(context),
                          style: GoogleFonts.almarai(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0f172a))),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 18, color: Color(0xFFef4444)),
                      const SizedBox(width: 8),
                      Text('delete'.tr(context),
                          style: GoogleFonts.almarai(
                              color: const Color(0xFFef4444))),
                    ]),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'edit') _showUserDialog(existing: user);
                  if (val == 'delete') _confirmDelete(user);
                },
              ),
      ),
    );
  }

  Widget _dialogField(
    BuildContext context,
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool isDark, {
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      style: GoogleFonts.almarai(
          color: isDark ? Colors.white : const Color(0xFF0f172a)),
      decoration: _fieldDecor(context: context, isDark: isDark, label: label, icon: icon),
      validator: validator,
    );
  }

  InputDecoration _fieldDecor({
    required BuildContext context,
    required bool isDark,
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.almarai(
          color: isDark ? Colors.white54 : const Color(0xFF64748b),
          fontSize: 13),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor:
          isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFf8fafc),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.08))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
