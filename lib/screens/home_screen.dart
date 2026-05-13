import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../models/employee.dart';
import '../models/absence.dart';
import '../models/user_role.dart';
import '../widgets/stats_bar.dart';
import '../widgets/employee_card.dart';
import 'employee_form_screen.dart';
import 'absence_screens.dart';
import 'user_management_screen.dart';
import 'login_screen.dart';
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
    return Directionality(
      textDirection: TextDirection.rtl,
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
                  backgroundColor: const Color(0xFF2563eb),
                  child: const Icon(Icons.add, color: Colors.white),
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
              colors: [Color(0xFF2563eb), Color(0xFF0ea5e9)],
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
                    const Text(
                      'إدارة العمال',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
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
                          syncService.isOfflineManual ? 'وضع يدوي' : (syncService.isOnline ? 'متصل' : 'غير متصل'),
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
                            isOnline ? 'أونلاين' : 'أوفلاين',
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
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20, left: 20, right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563eb), Color(0xFF0ea5e9)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 القائمة',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('نظام متابعة القوى العاملة',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12)),
                    const SizedBox(height: 12),
                    // User info chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_circle_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
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
                        icon: '➕',
                        label: 'إضافة عاملة جديدة',
                        onTap: () {
                          Navigator.pop(context);
                          _openForm(context);
                        },
                      ),
                      const SizedBox(height: 6),
                    ],

                    // 📅 قائمة الغيابات — tous
                    _sidebarBtn(
                      icon: '📅',
                      label: 'قائمة الغيابات',
                      badge: syncService.employees.where((e) => e.absence != null).length,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const AbsenceListScreen()));
                      },
                    ),
                    const SizedBox(height: 6),

                    // 🗃️ الأرشيف — tous
                    _sidebarBtn(
                      icon: '🗃️',
                      label: 'الأرشيف',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ArchiveScreen()));
                      },
                    ),
                    const SizedBox(height: 6),

                    // 👥 إدارة المستخدمين — Admin only
                    if (role.canManageUsers) ...[  
                      _sidebarBtn(
                        icon: '👥',
                        label: 'إدارة المستخدمين',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const UserManagementScreen()));
                        },
                      ),
                      const SizedBox(height: 6),
                    ],

                    const SizedBox(height: 8),
                    Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
                    const SizedBox(height: 6),

                    // ⚙️ الإعدادات
                    _SidebarExpandable(
                      icon: '⚙️',
                      label: 'الإعدادات',
                      children: [
                        _settingsBtn(
                          icon: syncService.isDarkMode ? '☀️' : '🌙',
                          label: syncService.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                          trailing: _buildToggle(syncService.isDarkMode),
                          onTap: () => syncService.toggleTheme(),
                        ),
                        if (role.canImportExport) ...[
                          _settingsBtn(
                            icon: '📥',
                            label: 'تصدير البيانات',
                            onTap: () { Navigator.pop(context); syncService.exportData(); },
                          ),
                          _settingsBtn(
                            icon: '📤',
                            label: 'استيراد البيانات',
                            onTap: () { Navigator.pop(context); syncService.importData(); },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey.withValues(alpha: 0.2), thickness: 1),
                    const SizedBox(height: 6),

                    // 🚪 تسجيل الخروج
                    _sidebarBtn(
                      icon: '🚪',
                      label: 'تسجيل الخروج',
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

  Widget _sidebarBtn({required String icon, required String label, required VoidCallback onTap, int badge = 0}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFf0f4ff),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              if (badge > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFea580c),
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

  Widget _settingsBtn({required String icon, required String label, VoidCallback? onTap, Widget? trailing}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFf0f4ff),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
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
        color: isOn ? const Color(0xFF2563eb) : Colors.grey[300],
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
            hintText: 'ابحث بالاسم أو رقم التسجيل...',
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
                const Text('لا يوجد عمال مطابقين', style: TextStyle(color: Colors.grey)),
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
            );
          },
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
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف ${employee.name}؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                Provider.of<SyncService>(context, listen: false).deleteEmployee(employee.reg);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العامل بنجاح')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbsenceDialog(BuildContext context, Employee employee) {
    String selectedType = 'غ غ ش';
    int days = 1;
    DateTime startDate = DateTime.now();
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          final returnDate = startDate.add(Duration(days: days));
          final formattedReturn = intl.DateFormat('yyyy/MM/dd').format(returnDate);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تسجيل غياب', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(employee.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563eb))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('نوع الغياب', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    mainAxisSpacing: 10, crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    physics: const NeverScrollableScrollPhysics(),
                    children: ['غ غ ش', 'عطلة سنوية', 'مرض', 'أخرى'].map((type) {
                      final sel = selectedType == type;
                      return GestureDetector(
                        onTap: () => setModal(() => selectedType = type),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFFfff7ed) : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: sel ? const Color(0xFFea580c) : Colors.grey[300]!),
                          ),
                          child: Text(type, style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: sel ? const Color(0xFFea580c) : null,
                          )),
                        ),
                      );
                    }).toList(),
                  ),
                  if (selectedType != 'غ غ ش') ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('عدد الأيام', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
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
                              const Text('تاريخ البدء', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
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
                          Text('تاريخ الالتحاق: $formattedReturn',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('غياب بدون إذن — سيسجل فوراً', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  // --- Reason field ---
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'السبب أو ملاحظة (اختياري)...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.note_outlined, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563eb))),
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
                          startDate: selectedType == 'غ غ ش' ? null : intl.DateFormat('yyyy/MM/dd').format(startDate),
                          days: selectedType == 'غ غ ش' ? null : days,
                          returnDate: selectedType == 'غ غ ش' ? null : formattedReturn,
                          reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
                        );
                        Provider.of<SyncService>(context, listen: false).addAbsence(employee.reg, absence);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563eb),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('✔ تسجيل الغياب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Sidebar expandable widget
class _SidebarExpandable extends StatefulWidget {
  final String icon;
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFf0f4ff),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(widget.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
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