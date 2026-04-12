import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/home_screen.dart';
import '../screens/absence_screen.dart';
import '../screens/conges_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/language_provider.dart';
import '../models/employee.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AbsenceScreen(),
    const CongesScreen(),
  ];

  Future<void> _shareAllEmployeesAsJson(List<Employee> employees) async {
    if (employees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد عمال للمشاركة')),
      );
      return;
    }

    try {
      final List<Map<String, dynamic>> jsonList = employees.map((e) => {
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
      final file = File('${directory.path}/employes_backup.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Sauvegarde Database (JSON)');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e')),
      );
    }
  }

  Future<void> _importEmployeesFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);

        final employees = jsonList.map((e) => Employee(
          name: e['name'] ?? '',
          reg: e['reg'] ?? '',
          phone: e['phone'],
          address: e['address'],
          blood: e['blood'],
          status: e['status'],
          notes: e['notes'],
        )).toList();

        await context.read<EmployeeProvider>().importEmployees(employees);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Base de données importée avec succès !')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur import JSON: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();
    final lang = context.watch<LanguageProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final List<String> _titles = [
      lang.t('إدارة العمال', 'Employés'),
      lang.t('الغيابات', 'Absences'),
      lang.t('الإجازات', 'Congés'),
    ];

    return Scaffold(
      extendBody: true, // Très important pour passer sous le fond de la bottom bar
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            icon: Icon(themeProvider.mode == ThemeMode.dark ? Icons.wb_sunny : Icons.nights_stay),
            color: colorScheme.primary,
            onPressed: () => themeProvider.toggle(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 2),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withOpacity(0.2), blurRadius: 8, spreadRadius: 2)
                ],
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.transparent,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).cardColor,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface.withOpacity(0.8),
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: colorScheme.primary.withOpacity(0.3))),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.primary),
                          ),
                          child: Icon(Icons.diamond_outlined, size: 30, color: colorScheme.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            lang.t('عمالي', 'Mes employés'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        lang.t('العدد: ${employeeProvider.allEmployees.length}', 'EFFECTIF: ${employeeProvider.allEmployees.length}'),
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(Icons.language, color: colorScheme.primary),
                      title: Text(lang.t('اللغة الفرنسية', 'Langue Française')),
                      trailing: Switch(
                        activeColor: colorScheme.primary,
                        value: lang.isFrench,
                        onChanged: (_) => lang.toggleLanguage(),
                      ),
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.download, color: colorScheme.primary),
                      title: Text(lang.t('تصدير قاعدة البيانات (JSON)', 'Exporter la base (JSON)')),
                      onTap: () {
                        Navigator.pop(context);
                        _shareAllEmployeesAsJson(employeeProvider.allEmployees);
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(Icons.upload, color: colorScheme.primary),
                      title: Text(lang.t('استيراد قاعدة البيانات (JSON)', 'Importer la base (JSON)')),
                      onTap: () {
                        Navigator.pop(context);
                        _importEmployeesFromJson();
                      },
                    ),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    ListTile(
                      leading: Icon(themeProvider.mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode, color: colorScheme.primary),
                      title: Text(lang.t('الوضع الداكن', 'Mode Sombre')),
                      trailing: Switch(
                        activeColor: colorScheme.primary,
                        value: themeProvider.mode == ThemeMode.dark,
                        onChanged: (_) => themeProvider.toggle(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: employeeProvider.isSelectionMode ? const Offset(0, 2) : Offset.zero,
        curve: Curves.easeInOutBack,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: NavigationBar(
                    backgroundColor: Colors.transparent,
                    indicatorColor: colorScheme.primary.withOpacity(0.2),
                    elevation: 0,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people, color: colorScheme.primary),
                        label: lang.t('العمال', 'Employés'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.event_busy_outlined),
                        selectedIcon: Icon(Icons.event_busy, color: colorScheme.primary),
                        label: lang.t('الغيابات', 'Absences'),
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.beach_access_outlined),
                        selectedIcon: Icon(Icons.beach_access, color: colorScheme.primary),
                        label: lang.t('الإجازات', 'Congés'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

