import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';
import '../services/sync_service.dart';
import '../models/employee.dart';
import '../models/absence.dart';
import '../services/auth_service.dart';
import '../models/user_role.dart';
import '../utils/translations.dart';

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

// Modal bottom sheet — employee info + ALL absences (current + archived)
void _showEmployeeDetails(BuildContext context, Employee employee) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // Build a unified absence list: current first, then archived reversed
  final List<Map<String, dynamic>> allAbsences = [];
  if (employee.absence != null) {
    allAbsences.add({'absence': employee.absence!, 'isCurrent': true});
  }
  for (final ab in employee.archivedAbsences.reversed) {
    allAbsences.add({'absence': ab, 'isCurrent': false});
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'نقاهة':       return Colors.blue;
      case 'غ غ ش':      return Colors.red;
      case 'إجازة':       return Colors.green;
      case 'رخصة غياب':  return Colors.purple;
      default:            return Colors.orange;
    }
  }

  Icon _typeIcon(String type) {
    switch (type) {
      case 'نقاهة':       return const Icon(Icons.sick_outlined,        size: 14, color: Colors.blue);
      case 'غ غ ش':      return const Icon(Icons.block_outlined,        size: 14, color: Colors.red);
      case 'إجازة':       return const Icon(Icons.beach_access_outlined, size: 14, color: Colors.green);
      case 'رخصة غياب':  return const Icon(Icons.description_outlined,  size: 14, color: Colors.purple);
      default:            return const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.orange);
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Handle ──
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
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

                // ── Header: avatar + name + absence count ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563eb).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2563eb)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(employee.name,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(employee.reg,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary)),
                            ),
                          ],
                        ),
                      ),
                      // Total absence count badge
                      if (allAbsences.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.25)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${allAbsences.length}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                              Text('absence'.tr(context),
                                style: const TextStyle(fontSize: 10, color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Personal info chips ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8, runSpacing: 6,
                    children: [
                      _buildDetailChip(Icons.phone_outlined,          employee.phone,      Colors.green),
                      _buildDetailChip(Icons.location_on_outlined,    employee.address,    Colors.red),
                      _buildDetailChip(Icons.work_outline,            employee.workplace,  Colors.blueGrey),
                      _buildDetailChip(Icons.family_restroom_outlined, employee.status,    Colors.orange),
                      if (employee.children != null)
                        _buildDetailChip(Icons.child_care_outlined,
                          'children_count'.tr(context) + ': ${employee.children}', Colors.purple),
                      if (employee.blood.isNotEmpty)
                        _buildDetailChip(Icons.bloodtype_outlined,
                          'blood_type'.tr(context) + ': ${employee.blood}', Colors.redAccent),
                    ],
                  ),
                ),

                if (employee.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFfefce8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFfef08a)),
                      ),
                      child: Text(employee.notes,
                        style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.grey[300] : const Color(0xFF854d0e))),
                    ),
                  ),
                ],

                const Divider(height: 24),

                // ── Call buttons ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            final url = Uri.parse('tel:${employee.phone}');
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                          icon: const Icon(Icons.call, size: 18),
                          label: Text('call_phone'.tr(context),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
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
                            if (phone.startsWith('0')) phone = '213${phone.substring(1)}';
                            final url = Uri.parse('https://wa.me/$phone');
                            if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.message, size: 18),
                          label: Text('call_whatsapp'.tr(context),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
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
                ),

                const Divider(height: 24),

                // ── Section title: all absences ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.history_outlined, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('absence_history'.tr(context),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Absence list ──
                Expanded(
                  child: allAbsences.isEmpty
                    ? Center(
                        child: Text('no_absence_history'.tr(context),
                          style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: allAbsences.length,
                        itemBuilder: (ctx, i) {
                          final Absence ab     = allAbsences[i]['absence'];
                          final bool isCurrent = allAbsences[i]['isCurrent'];
                          final color          = _typeColor(ab.type);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isCurrent
                                ? color.withOpacity(0.06)
                                : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.04)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent ? color.withOpacity(0.35) : Colors.grey.withOpacity(0.15),
                                width: isCurrent ? 1.4 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _typeIcon(ab.type),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(ab.type,
                                        style: TextStyle(fontSize: 12,
                                          fontWeight: FontWeight.bold, color: color)),
                                    ),
                                    const SizedBox(width: 6),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text('current'.tr(ctx),
                                          style: const TextStyle(fontSize: 10,
                                            fontWeight: FontWeight.bold, color: Colors.green)),
                                      ),
                                    const Spacer(),
                                    Text('${i + 1}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('absence_date'.tr(ctx) + ': ${ab.date}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (ab.startDate != null || ab.returnDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'from'.tr(ctx) + ' ${ab.startDate ?? "--"}  →  ${ab.returnDate ?? "--"}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ),
                                if (ab.reason != null && ab.reason!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.note_alt_outlined, size: 13, color: color),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(ab.reason!,
                                          style: TextStyle(fontSize: 12, color: color)),
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

                SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
              ],
            ),
          );
        },
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
    final syncService = Get.find<SyncService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          title: Text('archive_selected'.tr(context)),
          content: Text('archive_confirm'.tr(context) + ' ' + '${_selectedRegs.length}' + ' ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              child: Text('archive_all'.tr(context)),
            ),
          ],
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
          SnackBar(content: Text('archived_success'.tr(context)), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _bulkDelete(BuildContext context) async {
    final syncService = Get.find<SyncService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
          title: Text('delete_selected'.tr(context)),
          content: Text('delete_confirm'.tr(context) + ' ' + '${_selectedRegs.length}' + ' ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('delete_all'.tr(context)),
            ),
          ],
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
          SnackBar(content: Text('deleted_success'.tr(context)), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SyncService>(
      builder: (syncService) {
        final role = context.read<AuthService>().currentRole;
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

        return Scaffold(
            appBar: isSelectionMode
                ? AppBar(
                    title: Text('selected_count'.tr(context) + ' ${_selectedRegs.length}'),
                    backgroundColor: const Color(0xFF1e3a5f),
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _clearSelection,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.select_all),
                        tooltip: 'select_all'.tr(context),
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
                      if (role.canManageAbsence) ...[
                        IconButton(
                          icon: const Icon(Icons.archive_outlined),
                          tooltip: 'archive_selected'.tr(context),
                          onPressed: () => _bulkArchive(context, filtered),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'delete_selected'.tr(context),
                          onPressed: () => _bulkDelete(context),
                        ),
                      ],
                    ],
                  )
                : AppBar(
                    title: Text('absences_list'.tr(context)),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
            body: Column(
              children: [
                // ── شريط البحث ──
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
                          hintText: 'search_absence_hint'.tr(context),
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

                // ── عدد النتائج ──
                Padding(
                  padding: const EdgeInsets.only(right: 18, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${filtered.length} ' + 'absence_records'.tr(context),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),

                // ── القائمة ──
                Expanded(
                  child: absentEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              
                              SizedBox(height: 12),
                              Text('no_absences'.tr(context),
                                  style: const TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text('no_match'.tr(context),
                                  style: const TextStyle(color: Colors.grey)),
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
    final syncService = Get.find<SyncService>();
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
                      color: Theme.of(context).colorScheme.primary,
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
              Text('absence_date'.tr(context) + ': ${ab.date}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                'start_date'.tr(context) + ': ${ab.startDate ?? "--"}   ·   ' + 'return_date'.tr(context) + ': ${ab.returnDate ?? "--"}',
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
                      Icon(Icons.note_alt_outlined,
                          size: 15, color: Theme.of(context).colorScheme.primary),
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
              
              // ── الأزرار (تظهر فقط في حالة عدم التحديد الجماعي ومسموح له) ──
              if (!isSelectionMode && context.read<AuthService>().currentRole.canManageAbsence) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await syncService.archiveAbsence(employee.reg);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('archived_success'.tr(context)), backgroundColor: Colors.green));
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_occurred'.tr(context)), backgroundColor: Colors.red));
                          }
                        },
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        label: Text('archive_selected'.tr(context)),
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
                            builder: (_) => AlertDialog(
                                title: Text('delete'.tr(context)),
                                content:
                                    Text('confirm_delete'.tr(context) + ' ${employee.name} ?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text('cancel'.tr(context))),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: Text('delete'.tr(context)),
                                  ),
                                ],
                              ),
                          );
                          if (ok == true && context.mounted) {
                            try {
                              await syncService.removeAbsence(employee.reg);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('deleted_success'.tr(context)), backgroundColor: Colors.green));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_occurred'.tr(context)), backgroundColor: Colors.red));
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text('delete'.tr(context)),
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
    return Scaffold(
        appBar: AppBar(
          title: Text('archive_menu'.tr(context)),
          backgroundColor: Colors.blueGrey[700],
          foregroundColor: Colors.white,
        ),
        body: GetBuilder<SyncService>(
          builder: (syncService) {
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
                        hintText: 'search_absence_hint'.tr(context),
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
                        '${filtered.length} ' + 'absence_records'.tr(context),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),

                // ── القائمة ──
                Expanded(
                  child: allArchived.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🗃️', style: TextStyle(fontSize: 52)),
                              const SizedBox(height: 12),
                              Text('empty_archive'.tr(context),
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Text('no_match'.tr(context),
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
                                                  'from'.tr(context) + ' ${ab.startDate ?? "--"} → ${ab.returnDate ?? "--"}',
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
                                          if (context.read<AuthService>().currentRole.canManageAbsence)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                try {
                                                  await syncService.deleteFromArchive(e.reg, archIdx);
                                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('deleted_success'.tr(context)), backgroundColor: Colors.green));
                                                } catch (err) {
                                                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_occurred'.tr(context)), backgroundColor: Colors.red));
                                                }
                                              },
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
    );
  }
}
