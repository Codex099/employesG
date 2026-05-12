import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../widgets/stats_bar.dart';
import '../widgets/employee_card.dart';
import 'employee_form_screen.dart';
import 'absence_screens.dart';
import '../models/absence.dart';
import '../models/employee.dart';
import 'package:intl/intl.dart' as intl;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _buildDrawer(context),
        body: Column(
          children: [
            _buildHeader(context),
            const StatsBar(),
            _buildSearchBox(),
            Expanded(
              child: _buildEmployeeList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openForm(context),
          backgroundColor: const Color(0xFF2563eb),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 40,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF2563eb), Color(0xFF0ea5e9)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نظام إدارة العمال',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (syncService.isOnline && !syncService.isOfflineManual) ? Colors.greenAccent : Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (syncService.isOnline && !syncService.isOfflineManual) ? 'متصل' : (syncService.isOfflineManual ? 'وضع يدوي' : 'غير متصل'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (syncService.isSyncing) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Text('أونلاين', style: TextStyle(color: Colors.white, fontSize: 10)),
              Switch(
                value: !syncService.isOfflineManual,
                onChanged: (_) => syncService.toggleOfflineMode(),
                activeColor: Colors.white,
                activeTrackColor: Colors.greenAccent.withOpacity(0.5),
              ),
              IconButton(
                icon: Icon(
                  syncService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => syncService.toggleTheme(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final syncService = Provider.of<SyncService>(context);
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563eb), Color(0xFF0ea5e9)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋 القائمة', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('نظام متابعة القوى العاملة', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF2563eb)),
            title: const Text('إضافة عاملة جديدة'),
            onTap: () {
              Navigator.pop(context);
              _openForm(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined, color: Colors.orange),
            title: const Text('قائمة الغيابات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AbsenceListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined, color: Colors.blueGrey),
            title: const Text('الأرشيف'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchiveScreen()));
            },
          ),
          const Divider(),
          ExpansionTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('الإعدادات'),
            children: [
              ListTile(
                leading: Icon(syncService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                title: Text(syncService.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي'),
                onTap: () => syncService.toggleTheme(),
              ),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('تصدير البيانات (JSON)'),
                onTap: () => syncService.exportData(),
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('استيراد البيانات (JSON)'),
                onTap: () => syncService.importData(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'ابحث بالاسم أو رقم التسجيل...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Consumer<SyncService>(
      builder: (context, syncService, child) {
        final filteredEmployees = syncService.employees.where((e) {
          final query = _searchQuery.toLowerCase();
          return e.name.toLowerCase().contains(query) || e.reg.contains(query);
        }).toList();

        if (filteredEmployees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text('لا يوجد عمال مطابقين', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredEmployees.length,
          itemBuilder: (context, index) {
            final employee = filteredEmployees[index];
            return EmployeeCard(
              employee: employee,
              onEdit: () => _openForm(context, employee: employee),
              onDelete: () => _confirmDelete(context, employee),
              onAbsent: () => _showAbsenceDialog(context, employee),
            );
          },
        );
      },
    );
  }

  void _openForm(BuildContext context, {dynamic employee}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormScreen(employee: employee),
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic employee) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف ${employee.name}؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<SyncService>(context, listen: false).deleteEmployee(employee.reg);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف العامل بنجاح')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
  void _showAbsenceDialog(BuildContext context, Employee employee) {
    String selectedType = 'غ غ ش';
    int days = 1;
    DateTime startDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final returnDate = startDate.add(Duration(days: days));
          final formattedReturnDate = intl.DateFormat('yyyy/MM/dd', 'ar').format(returnDate);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              padding: EdgeInsets.only(
                left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 40, top: 10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  Text('📅 تسجيل غياب -- ${employee.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563eb))),
                  const SizedBox(height: 20),
                  const Text('نوع الغياب', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: ['غ غ ش', 'عطلة سنوية', 'مرض', 'أخرى'].map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (val) { if (val) setModalState(() => selectedType = type); },
                        selectedColor: const Color(0xFFfff7ed),
                        labelStyle: TextStyle(color: isSelected ? const Color(0xFFea580c) : Colors.black, fontWeight: FontWeight.bold),
                        side: BorderSide(color: isSelected ? const Color(0xFFea580c) : Colors.grey[300]!),
                      );
                    }).toList(),
                  ),
                  if (selectedType != 'غ غ ش') ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('عدد الأيام', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  IconButton(onPressed: () => setModalState(() => days = days > 1 ? days - 1 : 1), icon: const Icon(Icons.remove_circle_outline)),
                                  Text('$days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(onPressed: () => setModalState(() => days++), icon: const Icon(Icons.add_circle_outline)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('تاريخ البدء', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                  if (picked != null) setModalState(() => startDate = picked);
                                },
                                child: Text(intl.DateFormat('yyyy/MM/dd').format(startDate)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text('تاريخ الالتحاق: $formattedReturnDate', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final absence = Absence(
                          type: selectedType,
                          date: intl.DateFormat('yyyy/MM/dd').format(DateTime.now()),
                          startDate: selectedType == 'غ غ ش' ? null : intl.DateFormat('yyyy/MM/dd').format(startDate),
                          days: selectedType == 'غ غ ش' ? null : days,
                          returnDate: selectedType == 'غ غ ش' ? null : formattedReturnDate,
                        );
                        Provider.of<SyncService>(context, listen: false).addAbsence(employee.reg, absence);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563eb), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('تسجيل الغياب', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}