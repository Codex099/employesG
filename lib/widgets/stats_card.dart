import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../providers/language_provider.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? colorScheme.surface : Colors.white,
            isDark ? colorScheme.surface.withOpacity(0.8) : Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.4)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : colorScheme.primary.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: lang.t('إجمالي', 'TOTAL'), value: provider.totalEmployees, isPrimary: true),
          _StatItem(label: lang.t('متزوج', 'MARIÉ(E)'), value: provider.marriedCount),
          _StatItem(label: lang.t('أعزب', 'CÉLIB.'), value: provider.singleCount),
          _StatItem(label: lang.t('بهاتف', 'AVEC TÉL'), value: provider.withPhoneCount),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;
  final bool isPrimary;

  const _StatItem({required this.label, required this.value, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: isPrimary ? 28 : 22,
            fontWeight: FontWeight.w900,
            color: isPrimary ? colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: isPrimary ? colorScheme.primary.withOpacity(0.8) : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}