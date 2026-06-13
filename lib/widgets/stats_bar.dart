import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import '../services/sync_service.dart';
import '../main.dart';
import '../utils/translations.dart';

class StatsBar extends StatelessWidget {
  final String? selectedStatus;
  final Function(String? status) onFilterChanged;

  const StatsBar({
    super.key,
    this.selectedStatus,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SyncService>(
      builder: (syncService) {
        final employees = syncService.employees;
        final total = employees.length;
        final absentCount = employees.where((e) => e.absence != null).length;
        final presentCount = employees.where((e) => e.absence == null).length;

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
              _buildStatItem(
                context,
                'total_count'.tr(context),
                total.toString(),
                Theme.of(context).colorScheme.primary,
                null,
              ),
              _buildStatDivider(),
              _buildStatItem(
                context,
                'filter_absent'.tr(context),
                absentCount.toString(),
                Theme.of(context).colorScheme.error,
                'absent',
              ),
              _buildStatDivider(),
              _buildStatItem(
                context,
                'filter_present'.tr(context),
                presentCount.toString(),
                Theme.of(context).colorScheme.secondary,
                'present',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color, String? status) {
    final isSelected = selectedStatus == status;
    return InkWell(
      onTap: () => onFilterChanged(isSelected ? null : status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isSelected ? color : color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
