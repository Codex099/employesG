import 'package:flutter/material.dart';
import '../models/employee.dart';

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
    required this.onAbsent,
  });

  final VoidCallback onAbsent;

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
                  colors: [Color(0xFF2563eb), Color(0xFF0ea5e9)],
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
                        color: const Color(0xFF2563eb).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563eb),
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
                              color: const Color(0xFF2563eb).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              employee.reg,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563eb),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons in Header
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      color: Colors.blue,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      color: const Color(0xFFef4444),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(Icons.phone_outlined, employee.phone, Colors.green),
                    _buildChip(Icons.work_outline, employee.workplace, Colors.blueGrey),
                    _buildChip(Icons.family_restroom_outlined, employee.status, Colors.orange),
                    if (employee.blood.isNotEmpty)
                      _buildChip(Icons.bloodtype_outlined, employee.blood, Colors.red),
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
                              'غائب: ${employee.absence!.type}',
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
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('تعديل'),
                          style: TextButton.styleFrom(backgroundColor: const Color(0xFF2563eb).withOpacity(0.1), foregroundColor: const Color(0xFF2563eb)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onAbsent,
                          icon: const Icon(Icons.calendar_month_outlined, size: 18),
                          label: const Text('غياب'),
                          style: TextButton.styleFrom(backgroundColor: Colors.orange.withOpacity(0.1), foregroundColor: Colors.orange),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('حذف'),
                          style: TextButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1), foregroundColor: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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