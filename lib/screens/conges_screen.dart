import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/conge_provider.dart';
import '../providers/employee_provider.dart';
import '../models/conge.dart';

class CongesScreen extends StatelessWidget {
  const CongesScreen({super.key});

  void _showAddCongeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddCongeForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: const TabBar(
          tabs: [
            Tab(text: 'الطلبات'), // En attente
            Tab(text: 'المقبولة'), // Approuvés
            Tab(text: 'السجل'), // Historique
          ],
        ),
        body: Stack(
          children: [
            const TabBarView(
              children: [
                _CongesList(statusType: 'en_attente'),
                _CongesList(statusType: 'approuvé'),
                _CongesList(statusType: 'historique'),
              ],
            ),
            Positioned(
              bottom: 100, // Identique à HomeScreen
              right: 16,
              child: GestureDetector(
                onTap: () => _showAddCongeBottomSheet(context),
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
      ),
    );
  }
}

class _CongesList extends StatelessWidget {
  final String statusType;

  const _CongesList({required this.statusType});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CongeProvider>();
    List<Conge> list;

    switch (statusType) {
      case 'en_attente':
        list = provider.congesEnAttente;
        break;
      case 'approuvé':
        list = provider.congesApprouves;
        break;
      case 'historique':
      default:
        list = provider.historiqueConges;
        break;
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.beach_access, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد إجازات',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final conge = list[index];
        return _buildCongeCard(context, conge, provider);
      },
    );
  }

  Widget _buildCongeCard(BuildContext context, Conge conge, CongeProvider provider) {
    Color statusColor;
    String statusText;
    switch (conge.status) {
      case 'approuvé':
        statusColor = Colors.green;
        statusText = 'مقبول';
        break;
      case 'refusé':
        statusColor = Colors.red;
        statusText = 'مرفوض';
        break;
      case 'terminé':
        statusColor = Colors.grey;
        statusText = 'منتهي';
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
                  conge.employeeName,
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
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.date_range, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'من ${DateFormat('dd/MM/yyyy').format(conge.dateDebut)} إلى ${DateFormat('dd/MM/yyyy').format(conge.dateFin)}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'المدة: ${conge.nombreJours} يوم',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 1.0, // Indication visuelle de durée, simulé
              backgroundColor: Colors.grey[200],
              color: statusColor,
            ),
            const SizedBox(height: 8),
            if (conge.motif.isNotEmpty)
              Text(
                'السبب: ${conge.motif}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            if (conge.status == 'en_attente') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => provider.refuserConge(conge.id),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('رفض'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => provider.approuverConge(conge.id),
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

class _AddCongeForm extends StatefulWidget {
  const _AddCongeForm();

  @override
  State<_AddCongeForm> createState() => _AddCongeFormState();
}

class _AddCongeFormState extends State<_AddCongeForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeId;
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 1));
  final _motifController = TextEditingController();

  int get _nombreJours => _dateFin.difference(_dateDebut).inDays + 1;

  @override
  void dispose() {
    _motifController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedEmployeeId != null) {
      if (_dateFin.isBefore(_dateDebut)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تاريخ النهاية يجب أن يكون بعد تاريخ البداية')),
        );
        return;
      }

      final employeeProvider = context.read<EmployeeProvider>();
      final congeProvider = context.read<CongeProvider>();

      final employee = employeeProvider.allEmployees
          .firstWhere((e) => e.reg == _selectedEmployeeId);

      final conge = Conge(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        employeeId: employee.reg,
        employeeName: employee.name,
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        motif: _motifController.text,
      );

      congeProvider.demanderConge(conge);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم تقديم طلب الإجازة بنجاح'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.blue,
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
              'طلب إجازة جديد',
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
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateDebut,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _dateDebut = date;
                          if (_dateFin.isBefore(_dateDebut)) {
                            _dateFin = _dateDebut;
                          }
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'من',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_dateDebut)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateFin,
                        firstDate: _dateDebut,
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _dateFin = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'إلى',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_dateFin)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calculate, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'المدة المحسوبة: $_nombreJours يوم',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motifController,
              decoration: const InputDecoration(
                labelText: 'السبب (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submit,
              child: const Text('تقديم الطلب', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
