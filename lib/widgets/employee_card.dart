import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/employee.dart';
import '../providers/language_provider.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCall;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
    required this.onCall,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  void _shareEmployee() {
    final buffer = StringBuffer();
    buffer.writeln('💎 PASS VIP: ${employee.name}');
    buffer.writeln('────────────────────');
    buffer.writeln('Matricule: ${employee.reg}');
    if (employee.status != null && employee.status!.isNotEmpty) {
      buffer.writeln('Poste/Statut: ${employee.status}');
    }
    if (employee.phone != null && employee.phone!.isNotEmpty) {
      buffer.writeln('Téléphone: ${employee.phone}');
    }
    if (employee.blood != null && employee.blood!.isNotEmpty) {
      buffer.writeln('Groupe sanguin: ${employee.blood}');
    }
    if (employee.address != null && employee.address!.isNotEmpty) {
      buffer.writeln('📍 ${employee.address}');
    }
    if (employee.notes != null && employee.notes!.isNotEmpty) {
      buffer.writeln('Notes VIP: ${employee.notes}');
    }
    Share.share(buffer.toString(), subject: 'Fiche employé');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primary.withOpacity(0.1) 
              : (isDark ? Theme.of(context).cardColor.withOpacity(0.5) : Colors.white.withOpacity(0.9)),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected 
                ? colorScheme.primary 
                : colorScheme.primary.withOpacity(isDark ? 0.15 : 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? colorScheme.primary.withOpacity(0.2) 
                  : (isDark ? Colors.black.withOpacity(0.3) : colorScheme.primary.withOpacity(0.05)),
              blurRadius: isSelected ? 30 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.primary.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 10)
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: colorScheme.surface,
                        child: Text(
                          employee.initials,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            employee.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MAT. ${employee.reg}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.ios_share, color: colorScheme.primary),
                        onPressed: _shareEmployee,
                        tooltip: 'Partager le Pass VIP',
                      ),
                    ),
                    if (employee.phone != null && employee.phone!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                          onPressed: () {
                            final uri = Uri.parse('https://wa.me/${employee.phone!.replaceAll(" ", "")}');
                            // Normalement utiliser launchUrl(uri) de url_launcher
                            // S'assurer qu'on gère le Future:
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          },
                          tooltip: 'WhatsApp',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.call, color: colorScheme.primary),
                          onPressed: onCall,
                          tooltip: 'Appeler',
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (employee.phone != null && employee.phone!.isNotEmpty)
                      _buildLuxChip(context, '📞', employee.phone!),
                    if (employee.blood != null && employee.blood!.isNotEmpty)
                      _buildLuxChip(context, '🩸', employee.blood!),
                    if (employee.address != null && employee.address!.isNotEmpty)
                      _buildLuxChip(context, '📍', employee.address!),
                    if (employee.status != null && employee.status!.isNotEmpty)
                      _buildLuxChip(context, '👤', employee.status!),
                  ],
                ),
                if (employee.notes != null && employee.notes!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, color: colorScheme.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            employee.notes!,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade300, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(lang.t('تعديل', 'MODIFIER'), style: TextStyle(color: colorScheme.primary, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onDelete,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.15),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(lang.t('حذف', 'RÉVOQUER'), style: const TextStyle(color: Colors.redAccent, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildLuxChip(BuildContext context, String emoji, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Text('$emoji  $text', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
