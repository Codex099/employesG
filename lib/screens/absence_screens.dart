import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../services/sync_service.dart';
import '../models/employee.dart';
import '../models/absence.dart';

// Helper chip widget for details modal
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

// Modal bottom sheet to display complete employee information (Observation/Notes, phone, details, etc.)
void _showEmployeeDetails(BuildContext context, Employee employee) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
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
                        color: const Color(0xFF2563eb).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563eb),
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
                              color: const Color(0xFF2563eb).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              employee.reg,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563eb),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                const Text(
                  'المعلومات الشخصية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563eb),
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
                      _buildDetailChip(Icons.child_care_outlined, 'الأولاد: ${employee.children}', Colors.purple),
                    if (employee.blood.isNotEmpty)
                      _buildDetailChip(Icons.bloodtype_outlined, 'فصيلة الدم: ${employee.blood}', Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 20),
                if (employee.notes.isNotEmpty) ...[
                  const Text(
                    'الملاحظات (Observation)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563eb),
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
                  const Text(
                    'تفاصيل الغياب الحالي',
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
                        Text('نوع الغياب: ${employee.absence!.type}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text('تاريخ تسجيل الغياب: ${employee.absence!.date}', style: const TextStyle(fontSize: 12)),
                        if (employee.absence!.startDate != null)
                          Text('تاريخ البدء: ${employee.absence!.startDate}', style: const TextStyle(fontSize: 12)),
                        if (employee.absence!.returnDate != null)
                          Text('تاريخ الالتحاق: ${employee.absence!.returnDate}', style: const TextStyle(fontSize: 12)),
                        if (employee.absence!.reason != null && employee.absence!.reason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('ملاحظة الغياب: ${employee.absence!.reason}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
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
                        label: const Text('اتصال مباشر', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        label: const Text('واتساب', style: TextStyle(fontWeight: FontWeight.bold)),
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
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ─────────────────────────────────────────
//  قائمة الغيابات الحالية (مع اختيار متعدد وبحث)
// ─────────────────────────────────────────
class AbsenceListScreen extends StatefulWidget {
  const AbsenceListScreen({super.key});

  @override
  State<AbsenceListScreen> createState() => _AbsenceListScreenState();
}

class _AbsenceListScreenState extends State<AbsenceListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedRegs = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSelection(String reg) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedRegs.contains(reg)) {
        _selectedRegs.remove(reg);
      } else {
        _selectedRegs.add(reg);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedRegs.clear();
    });
  }

  Future<void> _bulkArchive(BuildContext context, List<Employee> filteredList) async {
    final syncService = context.read<SyncService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الأرشفة الجماعية'),
          content: Text('هل تريد أرشفة غياب ${_selectedRegs.length} عامل(ين)؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              child: const Text('أرشفة الكل'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final selectedList = List<String>.from(_selectedRegs);
      for (final reg in selectedList) {
        await syncService.archiveAbsence(reg);
      }
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت أرشفة الغيابات المحددة')),
        );
      }
    }
  }

  Future<void> _bulkDelete(BuildContext context) async {
    final syncService = context.read<SyncService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف الجماعي'),
          content: Text('هل تريد حذف غياب ${_selectedRegs.length} عامل(ين)؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف الكل'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final selectedList = List<String>.from(_selectedRegs);
      for (final reg in selectedList) {
        await syncService.removeAbsence(reg);
      }
      _clearSelection();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الغيابات المحددة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncService>(
      builder: (context, syncService, _) {
        final absentEmployees =
            syncService.employees.where((e) => e.absence != null).toList();

        // تصفية البحث
        final filtered = _searchQuery.isEmpty
            ? absentEmployees
            : absentEmployees.where((e) {
                final q = _searchQuery.toLowerCase();
                final ab = e.absence!;
                return e.name.toLowerCase().contains(q) ||
                    e.reg.contains(q) ||
                    ab.type.toLowerCase().contains(q) ||
                    (ab.reason?.toLowerCase().contains(q) ?? false);
              }).toList();

        final isSelectionMode = _selectedRegs.isNotEmpty;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: isSelectionMode
                ? AppBar(
                    title: Text('تم تحديد ${_selectedRegs.length}'),
                    backgroundColor: const Color(0xFF1e3a5f),
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSelection,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        tooltip: 'تحديد الكل',
                        onPressed: () {
                          setState(() {
                            final visibleRegs = filtered.map((e) => e.reg).toList();
                            if (_selectedRegs.length == visibleRegs.length) {
                              _selectedRegs.clear();
                            } else {
                              _selectedRegs.addAll(visibleRegs);
                            }
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined),
                        tooltip: 'أرشفة المحدد',
                        onPressed: () => _bulkArchive(context, filtered),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'حذف المحدد',
                        onPressed: () => _bulkDelete(context),
                      ),
                    ],
                  )
                : AppBar(
                    title: const Text('قائمة الغيابات'),
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                  ),
            body: Column(
              children: [
                // ── شريط البحث ──
                if (absentEmployees.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم، رقم التسجيل، أو نوع الغياب...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                // ── القائمة ──
                Expanded(
                  child: absentEmployees.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('✅', style: TextStyle(fontSize: 52)),
                              SizedBox(height: 12),
                              Text('لا توجد غيابات مسجلة',
                                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text('لا توجد نتائج بحث مطابقة',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final employee = filtered[index];
                                final ab = employee.absence!;
                                final isSelected = _selectedRegs.contains(employee.reg);

                                return _AbsenceCard(
                                  employee: employee,
                                  ab: ab,
                                  isSelected: isSelected,
                                  isSelectionMode: isSelectionMode,
                                  onTap: () {
                                    if (isSelectionMode) {
                                      _toggleSelection(employee.reg);
                                    } else {
                                      _showEmployeeDetails(context, employee);
                                    }
                                  },
                                  onLongPress: () {
                                    if (!isSelectionMode) {
                                      _toggleSelection(employee.reg);
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AbsenceCard extends StatelessWidget {
  final Employee employee;
  final Absence ab;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AbsenceCard({
    required this.employee,
    required this.ab,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final syncService = context.read<SyncService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isSelected
            ? const BorderSide(color: Color(0xFF2563eb), width: 2)
            : BorderSide(color: Colors.transparent),
      ),
      color: isSelected
          ? (isDark ? Colors.blue.withOpacity(0.15) : const Color(0xFFeff6ff))
          : null,
      elevation: isSelected ? 4 : 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── اسم + نوع الغياب ──
              Row(
                children: [
                  if (isSelectionMode) ...[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: const Color(0xFF2563eb),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(employee.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(ab.type,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── التواريخ ──
              Text('تاريخ التسجيل: ${ab.date}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                'البدء: ${ab.startDate ?? "--"}   ·   التحاق: ${ab.returnDate ?? "--"}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              // ── الملاحظة ── (Observation)
              if (ab.reason != null && ab.reason!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFeff6ff),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFbfdbfe)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note_alt_outlined,
                          size: 15, color: Color(0xFF2563eb)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(ab.reason!,
                            style: const TextStyle(
                                color: Color(0xFF1d4ed8), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              
              // ── الأزرار (تظهر فقط في حالة عدم التحديد الجماعي) ──
              if (!isSelectionMode) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => syncService.archiveAbsence(employee.reg),
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: const Text('أرشفة'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content:
                                    Text('حذف غياب ${employee.name}؟'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('إلغاء')),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (ok == true && context.mounted) {
                            syncService.removeAbsence(employee.reg);
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('حذف'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.08),
                            foregroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  الأرشيف — مع بحث وعرض التفاصيل عند الضغط
// ─────────────────────────────────────────
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الأرشيف'),
          backgroundColor: Colors.blueGrey[700],
          foregroundColor: Colors.white,
        ),
        body: Consumer<SyncService>(
          builder: (context, syncService, _) {
            // بناء القائمة الكاملة
            final allArchived = <Map<String, dynamic>>[];
            for (var e in syncService.employees) {
              for (int i = 0; i < e.archivedAbsences.length; i++) {
                allArchived.add({
                  'employee': e,
                  'absence': e.archivedAbsences[i],
                  'index': i,
                });
              }
            }

            // ترتيب عكسي (الأحدث أولاً)
            final reversed = allArchived.reversed.toList();

            // تطبيق البحث
            final filtered = _query.isEmpty
                ? reversed
                : reversed.where((item) {
                    final Employee e = item['employee'];
                    final Absence ab = item['absence'];
                    final q = _query.toLowerCase();
                    return e.name.toLowerCase().contains(q) ||
                        e.reg.contains(q) ||
                        ab.type.contains(q) ||
                        (ab.reason?.toLowerCase().contains(q) ?? false);
                  }).toList();

            return Column(
              children: [
                // ── شريط البحث ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'ابحث بالاسم أو نوع الغياب...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.grey),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                // ── عدد النتائج ──
                if (allArchived.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 18, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${filtered.length} سجل',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),

                // ── القائمة ──
                Expanded(
                  child: allArchived.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🗃️', style: TextStyle(fontSize: 52)),
                              SizedBox(height: 12),
                              Text('الأرشيف فارغ',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text('لا توجد نتائج',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final Employee e = item['employee'];
                                final Absence ab = item['absence'];
                                final int archIdx = item['index'];

                                return Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  child: InkWell(
                                    onTap: () => _showEmployeeDetails(context, e),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(e.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15)),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueGrey
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(ab.type,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .blueGrey,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold)),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'من ${ab.startDate ?? "--"} → ${ab.returnDate ?? "--"}',
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12),
                                                ),
                                                if (ab.reason != null &&
                                                    ab.reason!.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .note_alt_outlined,
                                                          size: 13,
                                                          color: Colors.blue),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(ab.reason!,
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .blue)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () =>
                                                syncService.deleteFromArchive(
                                                    e.reg, archIdx),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
