import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/employee.dart';
import '../models/absence.dart';
import '../main.dart';
import '../utils/translations.dart';
import 'package:intl/intl.dart' as intl;

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAbsent;             // fallback dialog
  final VoidCallback? onTap;
  final VoidCallback? onShowAbsences;
  final void Function(Absence)? onSaveAbsence; // submit from embedded form

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onEdit,
    this.onDelete,
    this.onAbsent,
    this.onTap,
    this.onShowAbsences,
    this.onSaveAbsence,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: onAbsent != null ? () {
            HapticFeedback.mediumImpact();
            onAbsent!();
          } : null,
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Left accent border (RTL context, so it's on the right visually in LTR, but we'll use a Positioned)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kPrimaryDark, kPrimary],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar/Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  employee.reg,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons in Header
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: onEdit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        if (onDelete != null)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: onDelete,
                            color: Theme.of(context).colorScheme.error,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Info Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(Icons.phone_outlined, employee.phone, Theme.of(context).colorScheme.primary),
                        _buildChip(Icons.work_outline, employee.workplace, Colors.blueGrey),
                        _buildChip(Icons.family_restroom_outlined, (() {
                          final st = employee.status;
                          return st == 'متزوج' ? 'status_married'.tr(context) :
                                 st == 'أعزب' ? 'status_single'.tr(context) :
                                 st == 'أرمل' ? 'status_widowed'.tr(context) : st;
                        })(), Theme.of(context).colorScheme.secondary),
                        if (employee.blood.isNotEmpty)
                          _buildChip(Icons.bloodtype_outlined, employee.blood, Theme.of(context).colorScheme.error),
                        if (employee.absence != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  (() {
                                    final t = employee.absence!.type;
                                    final translated = t == 'نقاهة' ? 'sick_leave'.tr(context) :
                                                       t == 'ع ع ش' ? 'unauthorized_absence'.tr(context) :
                                                       t == 'إجازة' ? 'vacation'.tr(context) :
                                                       t == 'رخصة غياب' ? 'absence_permission'.tr(context) : t;
                                    return 'absent'.tr(context) + ': $translated';
                                  })(),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (employee.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFfefce8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          employee.notes,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey : const Color(0xFF854d0e),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
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
                            label: Text('call_phone'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                              if (phone.startsWith('0')) {
                                phone = '213${phone.substring(1)}';
                              }
                              final url = Uri.parse('https://wa.me/$phone');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.message, size: 18),
                            label: Text('call_whatsapp'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF14B8A6), // Teal-400 for WhatsApp
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Long-press sheet: history badges + embedded absence form ─────────────
  void _showAllAbsenceTypes(BuildContext context) {
    final allTypes = <Map<String, dynamic>>[];
    if (employee.absence != null) {
      allTypes.add({'type': employee.absence!.type, 'date': employee.absence!.date, 'isCurrent': true});
    }
    for (final ab in employee.archivedAbsences.reversed) {
      allTypes.add({'type': ab.type, 'date': ab.date, 'isCurrent': false});
    }

    // No history and no embedded form → open old dialog
    if (allTypes.isEmpty && onSaveAbsence == null) {
      if (onAbsent != null) onAbsent!();
      return;
    }

    Color typeColor(String t) {
      switch (t) {
        case 'نقاهة':      return Colors.blue;
        case 'ع ع ش':     return Colors.red;
        case 'إجازة':      return Colors.green;
        case 'رخصة غياب': return Colors.purple;
        default:           return Colors.orange;
      }
    }

    IconData typeIconData(String t) {
      switch (t) {
        case 'نقاهة':      return Icons.sick_outlined;
        case 'ع ع ش':     return Icons.block_outlined;
        case 'إجازة':      return Icons.beach_access_outlined;
        case 'رخصة غياب': return Icons.description_outlined;
        default:           return Icons.calendar_today_outlined;
      }
    }

    final bool canAdd = employee.absence == null && onSaveAbsence != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        String selectedType = 'ع ع ش';
        int days = 1;
        DateTime startDate = DateTime.now();
        final reasonCtrl = TextEditingController();

        return StatefulBuilder(builder: (ctx, setModal) {
          final returnDate = startDate.add(Duration(days: days));
          final fmt = intl.DateFormat('yyyy/MM/dd');

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom +
                  MediaQuery.of(ctx).padding.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(child: Container(
                    width: 40, height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  )),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      const Icon(Icons.event_busy_outlined, color: Colors.orange, size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(employee.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      if (allTypes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${allTypes.length} غياب',
                            style: const TextStyle(color: Colors.red,
                              fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                    ],
                  ),

                  // ── History badges ──
                  if (allTypes.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: allTypes.map((item) {
                        final t     = item['type'] as String;
                        final d     = item['date'] as String;
                        final isCur = item['isCurrent'] as bool;
                        final col   = typeColor(t);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: col.withOpacity(isCur ? 0.12 : 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: col.withOpacity(isCur ? 0.4 : 0.2),
                              width: isCur ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(typeIconData(t), size: 14, color: col),
                                const SizedBox(width: 5),
                                Text(t, style: TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.bold, color: col)),
                                if (isCur) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text('حالياً',
                                      style: TextStyle(fontSize: 9,
                                        fontWeight: FontWeight.bold, color: Colors.green)),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 3),
                              Text(d, style: TextStyle(fontSize: 10,
                                color: isDark ? Colors.white54 : Colors.grey[600])),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // ── Embedded form (only if no current absence) ──
                  if (canAdd) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Section title
                    Row(children: [
                      const Text('📅', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('تسجيل غياب جديد',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary)),
                    ]),
                    const SizedBox(height: 14),

                    // Type grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      mainAxisSpacing: 10, crossAxisSpacing: 10,
                      childAspectRatio: 1.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        {'اسم': 'نقاهة',       'emoji': '🤒', 'val': 'نقاهة'},
                        {'اسم': 'ع ع ش',       'emoji': '⛔', 'val': 'ع ع ش'},
                        {'اسم': 'إجازة',       'emoji': '🏖️', 'val': 'إجازة'},
                        {'اسم': 'رخصة غياب',  'emoji': '📄', 'val': 'رخصة غياب'},
                      ].map((item) {
                        final val = item['val']!;
                        final sel = selectedType == val;
                        final col = typeColor(val);
                        return GestureDetector(
                          onTap: () => setModal(() => selectedType = val),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel ? col.withOpacity(0.1) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel ? col : (isDark ? Colors.white24 : Colors.grey.shade300),
                                width: sel ? 2 : 1,
                              ),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item['emoji']!, style: const TextStyle(fontSize: 20)),
                                const SizedBox(height: 4),
                                Text(item['اسم']!, style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12,
                                  color: sel ? col : null)),
                              ]),
                          ),
                        );
                      }).toList(),
                    ),

                    // Days + Start date (hidden for ع ع ش)
                    if (selectedType != 'ع ع ش') ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('عدد الأيام',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => setModal(() => days = days > 1 ? days - 1 : 1),
                                ),
                                Expanded(child: Text('$days',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => setModal(() => days++),
                                ),
                              ]),
                            ),
                          ],
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('تاريخ البداية',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setModal(() => startDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(fmt.format(startDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, color: Colors.green, size: 15),
                          const SizedBox(width: 8),
                          Text('تاريخ العودة: ${fmt.format(returnDate)}',
                            style: const TextStyle(color: Colors.green,
                              fontWeight: FontWeight.bold, fontSize: 12)),
                        ]),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.red, size: 15),
                          SizedBox(width: 8),
                          Flexible(child: Text('غياب بدون إذن مسبق',
                            style: TextStyle(color: Colors.red,
                              fontWeight: FontWeight.bold, fontSize: 12))),
                        ]),
                      ),
                    ],

                    // Reason
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'ملاحظات اختيارية...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.note_outlined, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      ),
                    ),

                    // Submit
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final absence = Absence(
                            type: selectedType,
                            date: fmt.format(DateTime.now()),
                            startDate: selectedType == 'ع ع ش' ? null : fmt.format(startDate),
                            days: selectedType == 'ع ع ش' ? null : days,
                            returnDate: selectedType == 'ع ع ش' ? null : fmt.format(returnDate),
                            reason: reasonCtrl.text.trim().isEmpty
                              ? null : reasonCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                          onSaveAbsence!(absence);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('✔ تثبيت الغياب',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
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
}