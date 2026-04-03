import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/employee_provider.dart';
import '../providers/theme_provider.dart';
import '../models/employee.dart';
import '../widgets/employee_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/add_edit_dialog.dart';
import '../widgets/search_bar.dart';
import '../widgets/bottom_nav.dart';

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
    final themeProvider = context.watch<ThemeProvider>();
    final employees = provider.employees;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العمال'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(themeProvider.isDark ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () => themeProvider.toggle(),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: const Text(
                  'إعدادات التطبيق',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Icon(themeProvider.isDark ? Icons.dark_mode : Icons.light_mode),
                title: const Text('وضع السمة'),
                subtitle: Text(themeProvider.isDark ? 'الوضع الداكن مفعل' : 'الوضع الفاتح مفعل'),
                trailing: Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggle(),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('عن التطبيق'),
                subtitle: const Text('تطبيق إدارة العمال مع بحث وتصدير واستيراد'),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'نسخة 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
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
                      child: Text(
                        'لا يوجد عمال بعد\nاضغط + لإضافة عامل جديد',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('list'),
                      padding: const EdgeInsets.all(16),
                      itemCount: employees.length,
                      itemBuilder: (context, index) {
                        final employee = employees[index];
                        final originalIndex = provider.allEmployees.indexOf(employee);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: EmployeeCard(
                            employee: employee,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, -1),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const BottomNav(),
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
          TextButton(
            onPressed: () {
              context.read<EmployeeProvider>().deleteEmployee(index);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم حذف ${employee.name}')),
              );
            },
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
          TextButton(
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
}