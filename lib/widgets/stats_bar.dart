import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import '../services/sync_service.dart';
import '../main.dart';
import '../utils/translations.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SyncService>(
      builder: (syncService) {
        final employees = syncService.employees;
        final total = employees.length;
        final married = employees.where((e) => e.status == 'متزوج').length;
        final single = employees.where((e) => e.status == 'أعزب').length;
        final widowed = employees.where((e) => e.status == 'أرمل').length;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('total_count'.tr(context), total.toString(), Theme.of(context).colorScheme.primary),
              _buildStatDivider(),
              _buildStatItem('status_married'.tr(context), married.toString(), Theme.of(context).colorScheme.secondary),
              _buildStatDivider(),
              _buildStatItem('status_single'.tr(context), single.toString(), Theme.of(context).colorScheme.primary.withOpacity(0.7)),
              _buildStatDivider(),
              _buildStatItem('status_widowed'.tr(context), widowed.toString(), Theme.of(context).colorScheme.error),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }
}
