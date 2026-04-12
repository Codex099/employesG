import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/language_provider.dart';
import '../models/employee.dart';
import '../widgets/employee_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/add_edit_dialog.dart';
import '../widgets/search_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<EmployeeProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final employees = provider.employees;
    final isSelectionMode = provider.isSelectionMode;

    return Stack(
      children: [
        Column(
          children: [
            const StatsCard(),
            SearchBarWidget(controller: _searchController),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: employees.isEmpty
                    ? Center(
                        key: const ValueKey('empty'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد عمال بعد\nاضغط + لإضافة عامل جديد',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        key: const ValueKey('list'),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding en bas pour le FAB
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          final originalIndex = provider.allEmployees.indexOf(employee);
                          final isSelected = provider.selectedRegs.contains(employee.reg);

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: EmployeeCard(
                              employee: employee,
                              isSelected: isSelected,
                              onLongPress: () {
                                provider.toggleSelection(employee.reg);
                              },
                              onTap: isSelectionMode ? () {
                                provider.toggleSelection(employee.reg);
                              } : null,
                              onEdit: () => _showAddEditDialog(context, originalIndex),
                              onDelete: () => _showDeleteDialog(context, originalIndex),
                              onCall: () => _showCallDialog(context, employee),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
        
        // Mode Sélection : Floating Action Bar
        if (isSelectionMode)
          Positioned(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('تم تحديد ${provider.selectedRegs.length}', '${provider.selectedRegs.length} sélectionné(s)'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.blue),
                              onPressed: () => _shareSelectedEmployees(provider),
                              tooltip: 'Partager JSON',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSelectedEmployees(provider),
                              tooltip: 'Supprimer',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => provider.clearSelection(),
                              tooltip: 'Annuler',
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        // Bouton d'ajout classique
        if (!isSelectionMode)
          Positioned(
            bottom: 100, // On le remonte au-dessus de la barre de navigation
            right: 16,
            child: GestureDetector(
            onTap: () => _showAddEditDialog(context, -1),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEditDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AddEditDialog(employeeIndex: index),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    final employee = context.read<EmployeeProvider>().allEmployees[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${employee.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () {
              context.read<EmployeeProvider>().deleteEmployee(index);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حذف ${employee.name}')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showCallDialog(BuildContext context, Employee employee) {
    if (employee.phone == null || employee.phone!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(employee.name),
        content: Text(employee.phone!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final url = Uri.parse('tel:${employee.phone}');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
            child: const Text('اتصال'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareSelectedEmployees(EmployeeProvider provider) async {
    final employeesToShare = provider.allEmployees.where((e) => provider.selectedRegs.contains(e.reg)).toList();
    if (employeesToShare.isEmpty) return;

    try {
      final List<Map<String, dynamic>> jsonList = employeesToShare.map((e) => {
        'name': e.name,
        'reg': e.reg,
        'phone': e.phone,
        'address': e.address,
        'blood': e.blood,
        'status': e.status,
        'notes': e.notes,
      }).toList();
      
      final jsonString = jsonEncode(jsonList);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/selection_employes.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Employés Sélectionnés (JSON)');
      provider.clearSelection();
    } catch (e) {
      // ignore
    }
  }

  void _deleteSelectedEmployees(EmployeeProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suppression multiple'),
        content: Text('Voulez-vous révoquer les ${provider.selectedRegs.length} employé(s) sélectionné(s) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop();
              for (var reg in provider.selectedRegs.toList()) {
                final index = provider.allEmployees.indexWhere((e) => e.reg == reg);
                if (index != -1) provider.deleteEmployee(index);
              }
              provider.clearSelection();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employés supprimés !')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.2), foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}