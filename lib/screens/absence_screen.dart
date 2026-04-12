import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/absence_provider.dart';
import '../providers/employee_provider.dart';
import '../models/absence.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  String _selectedFilter = 'tous';

  void _showAddAbsenceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddAbsenceForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final absenceProvider = context.watch<AbsenceProvider>();
    final absences = absenceProvider.filterByStatus(_selectedFilter);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip('الكل', 'tous'),
                    const SizedBox(width: 8),
                    _buildFilterChip('قيد الانتظار', 'en_attente'),
                    const SizedBox(width: 8),
                    _buildFilterChip('مقبول', 'approuvé'),
                    const SizedBox(width: 8),
                    _buildFilterChip('مرفوض', 'refusé'),
                  ],
                ),
              ),
              Expanded(
                child: absences.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد غيابات مسجلة',
                              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        itemCount: absences.length,
                        itemBuilder: (context, index) {
                          final absence = absences[index];
                          return _buildAbsenceCard(absence, absenceProvider);
                        },
                      ),
              )
            ],
          ),
          Positioned(
            bottom: 100, // Identique à HomeScreen
            right: 16,
            child: GestureDetector(
              onTap: () => _showAddAbsenceBottomSheet(context),
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
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildAbsenceCard(Absence absence, AbsenceProvider provider) {
    Color statusColor;
    String statusText;
    switch (absence.status) {
      case 'approuvé':
        statusColor = Colors.green;
        statusText = 'مقبول';
        break;
      case 'refusé':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'قيد الانتظار';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  absence.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'التاريخ: ${DateFormat('dd/MM/yyyy').format(absence.date)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'النوع: ${absence.type}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            if (absence.justification.isNotEmpty)
              Text(
                'التبرير: ${absence.justification}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (absence.status == 'en_attente') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => provider.updateStatus(absence.id, 'refusé'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('رفض'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => provider.updateStatus(absence.id, 'approuvé'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('قبول'),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

class _AddAbsenceForm extends StatefulWidget {
  const _AddAbsenceForm();

  @override
  State<_AddAbsenceForm> createState() => _AddAbsenceFormState();
}

class _AddAbsenceFormState extends State<_AddAbsenceForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  String _selectedType = 'maladie';
  DateTime _selectedDate = DateTime.now();
  final _justificationController = TextEditingController();

  final Map<String, String> _types = {
    'maladie': 'مرض',
    'personnel': 'شخصي',
    'autre': 'آخر',
  };

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedEmployeeId != null) {
      final employeeProvider = context.read<EmployeeProvider>();
      final absenceProvider = context.read<AbsenceProvider>();

      final employee = employeeProvider.allEmployees
          .firstWhere((e) => e.reg == _selectedEmployeeId);

      final absence = Absence(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: employee.reg,
        employeeName: employee.name,
        type: _types[_selectedType]!,
        date: _selectedDate,
        justification: _justificationController.text,
      );

      absenceProvider.addAbsence(absence);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تمت إضافة الغياب بنجاح!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<EmployeeProvider>().allEmployees;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تسجيل غياب جديد',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'العامل',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: employees.map((e) {
                return DropdownMenuItem<String>(
                  value: e.reg,
                  child: Text(e.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedEmployeeId = val;
                });
              },
              validator: (val) => val == null ? 'يرجى اختيار عامل' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'نوع الغياب',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              items: _types.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _justificationController,
              decoration: const InputDecoration(
                labelText: 'التبرير (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: const Text('حفظ', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
