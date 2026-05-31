import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../models/employee.dart';
import '../models/absence.dart';
import '../models/user_role.dart';
import '../widgets/stats_bar.dart';
import '../widgets/employee_card.dart';
import '../widgets/notification_banner.dart';
import 'employee_form_screen.dart';
import 'absence_screens.dart';
import 'user_management_screen.dart';
import 'login_screen.dart';
import '../utils/translations.dart';
import 'package:intl/intl.dart' as intl;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return NotificationBannerWrapper(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(context),
        body: Column(
          children: [
            _buildHeader(context),
            const StatsBar(),
            _buildSearchBox(),
            Expanded(child: _buildEmployeeList()),
          ],
        ),
        floatingActionButton: Consumer<AuthService>(
          builder: (_, auth, __) => auth.currentRole.canAdd
              ? FloatingActionButton(
                onPressed: () => _openForm(context),
                  child: const Icon(Icons.add),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        final isOnline = syncService.isOnline && !syncService.isOfflineManual;
        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            bottom: 40,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0B5F7A), Color(0xFF0891B2)], // kPrimaryDark to kPrimary
            ),
          ),
          child: Row(
            children: [
              // Menu button
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('☰', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'labor_management'.tr(context),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.greenAccent : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          syncService.isOfflineManual ? 'manual_mode'.tr(context) : (syncService.isOnline ? 'online'.tr(context) : 'offline'.tr(context)),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        if (syncService.isSyncing) ...[
                          const SizedBox(width: 8),
                          const SizedBox(width: 10, height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Online/Offline toggle
              Row(
                children: [
                  GestureDetector(
                    onTap: () => syncService.toggleOfflineMode(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.greenAccent.withValues(alpha: 0.25)
                            : Colors.red.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline ? Icons.wifi : Icons.wifi_off,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'online'.tr(context) : 'offline'.tr(context),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      syncService.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      color: Colors.white, size: 20,
                    ),
                    onPressed: () => syncService.toggleTheme(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: (syncService.isSyncing || syncService.isOfflineManual) 
                        ? null 
                        : () => syncService.fetchFromSheets(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer2<SyncService, AuthService>(
      builder: (context, syncService, auth, _) {
        final role = auth.currentRole;
        final user = auth.currentUser;
        return Drawer(
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  bottom: 24, left: 20, right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF0B5F7A), Color(0xFF0891B2)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dashboard_outlined, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text('home_menu'.tr(context),
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('labor_system'.tr(context),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12)),
                    const SizedBox(height: 16),
                    // User info chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_circle_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${user?.fullName ?? user?.username ?? ''} · ${role.label}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // ➕ إضافة — Admin + Manager only
                    if (role.canAdd) ...[  
                      _sidebarBtn(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'add_employee'.tr(context),
                        onTap: () {
                          Navigator.pop(context);
                          _openForm(context);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    // 📅 قائمة الغيابات — tous
                    _sidebarBtn(
                      icon: Icons.calendar_month_outlined,
                      label: 'absences_menu'.tr(context),
                      badge: syncService.employees.where((e) => e.absence != null).length,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AbsenceListScreen()));
                      },
                    ),
                    const SizedBox(height: 8),

                    // 🗃️ الأرشيف — tous
                    _sidebarBtn(
                      icon: Icons.archive_outlined,
                      label: 'archive_menu'.tr(context),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ArchiveScreen()));
                      },
                    ),
                    const SizedBox(height: 8),

                    // 👥 إدارة المستخدمين — Admin only
                    if (role.canManageUsers) ...[  
                      _sidebarBtn(
                        icon: Icons.people_alt_outlined,
                        label: 'user_management'.tr(context),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const UserManagementScreen()));
                        },
                      ),
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 8),
                    Divider(color: Colors.grey.withValues(alpha: 0.15), thickness: 1),
                    const SizedBox(height: 8),

                    // ⚙️ الإعدادات
                    _SidebarExpandable(
                      icon: Icons.settings_outlined,
                      label: 'settings'.tr(context),
                      children: [
                        _settingsBtn(
                          icon: syncService.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          label: syncService.isDarkMode ? 'light_mode'.tr(context) : 'dark_mode'.tr(context),
                          trailing: _buildToggle(syncService.isDarkMode),
                          onTap: () => syncService.toggleTheme(),
                        ),
                        _settingsBtn(
                          icon: Icons.language,
                          label: 'language'.tr(context),
                          onTap: () { Navigator.pop(context); syncService.toggleLanguage(); },
                        ),
                        if (role.canImportExport) ...[
                          _settingsBtn(
                            icon: Icons.file_download_outlined,
                            label: 'export_data'.tr(context),
                            onTap: () { Navigator.pop(context); syncService.exportData(); },
                          ),
                          _settingsBtn(
                            icon: Icons.file_upload_outlined,
                            label: 'import_data'.tr(context),
                            onTap: () { Navigator.pop(context); syncService.importData(); },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey.withValues(alpha: 0.15), thickness: 1),
                    const SizedBox(height: 8),

                    // 🚪 تسجيل الخروج
                    _sidebarBtn(
                      icon: Icons.logout_outlined,
                      label: 'logout'.tr(context),
                      onTap: () async {
                        Navigator.pop(context);
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sidebarBtn({required IconData icon, required String label, required VoidCallback onTap, int badge = 0}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isDark ? Colors.blue[300] : primaryColor),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsBtn({required IconData icon, required String label, VoidCallback? onTap, Widget? trailing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : primaryColor.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isDark ? Colors.blue[300]?.withOpacity(0.8) : primaryColor.withOpacity(0.8)),
              const SizedBox(width: 12),
              Expanded(child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(bool isOn) {
    return Container(
      width: 44, height: 24,
      decoration: BoxDecoration(
        color: isOn ? Theme.of(context).colorScheme.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        alignment: isOn ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          width: 18, height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'search_hint'.tr(context),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        final filtered = syncService.employees.where((e) {
          final q = _searchQuery.toLowerCase();
          return e.name.toLowerCase().contains(q) || e.reg.contains(q);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text('no_match'.tr(context), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final employee = filtered[index];
            final role = context.read<AuthService>().currentRole;
            return EmployeeCard(
              employee: employee,
              onEdit: role.canEdit ? () => _openForm(context, employee: employee) : null,
              onDelete: role.canDelete ? () => _confirmDelete(context, employee) : null,
              onAbsent: role.canMarkAbsence ? () => _showAbsenceDialog(context, employee) : null,
              onTap: () => _showEmployeeDetails(context, employee),
              onSaveAbsence: role.canMarkAbsence
                  ? (absence) {
                      final author = context.read<AuthService>().currentUser?.fullName ?? '';
                      Provider.of<SyncService>(context, listen: false)
                          .addAbsence(employee.reg, absence, author: author);
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(BuildContext context, Employee employee) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = context.read<AuthService>().currentRole;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employee.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                employee.reg,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (role.canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () {
                            Navigator.pop(context);
                            _openForm(context, employee: employee);
                          },
                        ),
                      if (role.canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(context, employee);
                          },
                        ),
                    ],
                  ),
                  const Divider(height: 30),
                  Text(
                    'personal_info'.tr(context),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailChip(Icons.phone_outlined, employee.phone, Colors.green),
                      _buildDetailChip(Icons.location_on_outlined, employee.address, Colors.red),
                      _buildDetailChip(Icons.work_outline, employee.workplace, Colors.blueGrey),
                      _buildDetailChip(Icons.family_restroom_outlined, employee.status, Colors.orange),
                      if (employee.children != null)
                        _buildDetailChip(Icons.child_care_outlined, 'children_count'.tr(context) + ': ${employee.children}', Colors.purple),
                      if (employee.blood.isNotEmpty)
                        _buildDetailChip(Icons.bloodtype_outlined, 'blood_type'.tr(context) + ': ${employee.blood}', Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (employee.notes.isNotEmpty) ...[
                    Text(
                      'observations'.tr(context),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFfefce8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFfef08a)),
                      ),
                      child: Text(
                        employee.notes,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : const Color(0xFF854d0e),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (employee.absence != null) ...[
                    Text(
                      'current_absence'.tr(context),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('absence_type'.tr(context) + ': ${employee.absence!.type}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('absence_date'.tr(context) + ': ${employee.absence!.date}', style: const TextStyle(fontSize: 12)),
                          if (employee.absence!.startDate != null)
                            Text('start_date'.tr(context) + ': ${employee.absence!.startDate}', style: const TextStyle(fontSize: 12)),
                          if (employee.absence!.returnDate != null)
                            Text('return_date'.tr(context) + ': ${employee.absence!.returnDate}', style: const TextStyle(fontSize: 12)),
                          if (employee.absence!.reason != null && employee.absence!.reason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('observations'.tr(context) + ': ${employee.absence!.reason}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse('tel:${employee.phone}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Icons.call, size: 18),
                          label: Text('call_direct'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            String phone = employee.phone.replaceAll(' ', '');
                            if (phone.startsWith('0')) {
                              phone = '213${phone.substring(1)}';
                            }
                            final url = Uri.parse('https://wa.me/$phone');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.message, size: 18),
                          label: Text('whatsapp'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (employee.absence == null && role.canMarkAbsence) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAbsenceDialog(context, employee);
                        },
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text('register_absence_btn'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        );
      },
    );
  }

  void _openForm(BuildContext context, {Employee? employee}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EmployeeFormScreen(employee: employee),
    ));
  }

  void _confirmDelete(BuildContext context, Employee employee) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
          title: Text('delete'.tr(context) + ' ?'),
          content: Text('confirm_delete'.tr(context) + ' ${employee.name}؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(context))),
            TextButton(
              onPressed: () {
                Provider.of<SyncService>(context, listen: false).deleteEmployee(employee.reg);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('deleted_successfully'.tr(context))),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('delete'.tr(context)),
            ),
          ],
        ),
    );
  }

  void _showAbsenceHistory(BuildContext context, Employee employee) {
    // Build list: current absence first, then archived (newest first)
    final List<Map<String, dynamic>> allAbsences = [];
    if (employee.absence != null) {
      allAbsences.add({'absence': employee.absence!, 'isCurrent': true});
    }
    for (final ab in employee.archivedAbsences.reversed) {
      allAbsences.add({'absence': ab, 'isCurrent': false});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Handle bar ──
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 10),
                  child: Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.history, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'absence_history'.tr(context) + ' ${employee.name}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${allAbsences.length} ' + 'absences_count'.tr(context),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                // ── List ──
                if (allAbsences.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('no_absence_history'.tr(context), style: const TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: allAbsences.length,
                      itemBuilder: (context, index) {
                        final item = allAbsences[index];
                        final Absence ab = item['absence'];
                        final bool isCurrent = item['isCurrent'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.orange.withOpacity(0.06)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? Colors.orange.withOpacity(0.15)
                                          : Colors.blueGrey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ab.type == 'نقاهة' ? 'sick_leave'.tr(context) :
                                      ab.type == 'ع ع ش' ? 'unauthorized_absence'.tr(context) :
                                      ab.type == 'إجازة' ? 'vacation'.tr(context) :
                                      ab.type == 'رخصة غياب' ? 'absence_permission'.tr(context) : ab.type,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent ? Colors.orange : Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'current'.tr(context),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                      ),
                                    ),
                                  const Spacer(),
                                  Text(
                                    ab.date,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'from'.tr(context) + ' ${ab.startDate ?? "--"} → ${ab.returnDate ?? "--"}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (ab.reason != null && ab.reason!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.note_alt_outlined, size: 13, color: Colors.blue),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        ab.reason!,
                                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
      },
    );
  }

  void _showAbsenceDialog(BuildContext context, Employee employee) {
    String selectedType = 'ع ع ش';
    int days = 1;
    DateTime startDate = DateTime.now();
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final returnDate = startDate.add(Duration(days: days));
          final formattedReturn = intl.DateFormat('yyyy/MM/dd').format(returnDate);

          return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
                top: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'absence_type'.tr(context) + ' -- ${employee.reg}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      // ── Badge compteur d'absences ──
                      if ((employee.absence != null ? 1 : 0) + employee.archivedAbsences.length > 0)
                        GestureDetector(
                          onTap: () => _showAbsenceHistory(context, employee),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  '${(employee.absence != null ? 1 : 0) + employee.archivedAbsences.length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('absence_type'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    mainAxisSpacing: 10, crossAxisSpacing: 10,
                    childAspectRatio: 1.5,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      {'name': 'sick_leave'.tr(context), 'value': 'نقاهة', 'emoji': '🤒'},
                      {'name': 'unauthorized_absence'.tr(context), 'value': 'ع ع ش', 'emoji': '⛔'},
                      {'name': 'vacation'.tr(context), 'value': 'إجازة', 'emoji': '🏖️'},
                      {'name': 'absence_permission'.tr(context), 'value': 'رخصة غياب', 'emoji': '📄'},
                    ].map((item) {
                      final typeLabel = item['name']!;
                      final typeValue = item['value']!;
                      final emoji = item['emoji']!;
                      final sel = selectedType == typeValue;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedType = typeValue),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white24 : Colors.grey[300]!),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 6),
                              Text(typeLabel, style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: sel ? Theme.of(context).colorScheme.primary : null,
                              )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (selectedType != 'ع ع ش') ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('days_count'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(icon: const Icon(Icons.remove), onPressed: () => setModal(() => days = days > 1 ? days - 1 : 1)),
                                    Expanded(child: Text('$days', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                    IconButton(icon: const Icon(Icons.add), onPressed: () => setModal(() => days++)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('start_date_absence'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final picked = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                  if (picked != null) setModal(() => startDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(intl.DateFormat('yyyy/MM/dd').format(startDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Text('return_date'.tr(context) + ': $formattedReturn',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('unauthorized_warning'.tr(context), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'reason_hint'.tr(context),
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.note_outlined, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final absence = Absence(
                          type: selectedType,
                          date: intl.DateFormat('yyyy/MM/dd').format(DateTime.now()),
                          startDate: selectedType == 'ع ع ش' ? null : intl.DateFormat('yyyy/MM/dd').format(startDate),
                          days: selectedType == 'ع ع ش' ? null : days,
                          returnDate: selectedType == 'ع ع ش' ? null : formattedReturn,
                          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                        );
                        final author = context.read<AuthService>().currentUser?.fullName ?? '';
                        Provider.of<SyncService>(context, listen: false)
                            .addAbsence(employee.reg, absence, author: author);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('✔ ' + 'submit_absence'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }
}

// Sidebar expandable widget
class _SidebarExpandable extends StatefulWidget {
  final IconData icon;
  final String label;
  final List<Widget> children;
  const _SidebarExpandable({required this.icon, required this.label, required this.children});

  @override
  State<_SidebarExpandable> createState() => _SidebarExpandableState();
}

class _SidebarExpandableState extends State<_SidebarExpandable> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, size: 22, color: isDark ? Colors.blue[300] : primaryColor),
                  const SizedBox(width: 14),
                  Expanded(child: Text(widget.label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  AnimatedRotation(
                    turns: _open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.chevron_left, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Column(children: widget.children),
          ),
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}