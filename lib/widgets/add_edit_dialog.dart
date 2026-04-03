import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../models/employee.dart';

class AddEditDialog extends StatefulWidget {
  final int employeeIndex;

  const AddEditDialog({super.key, required this.employeeIndex});

  @override
  State<AddEditDialog> createState() => _AddEditDialogState();
}

class _AddEditDialogState extends State<AddEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  String? _status;
  String? _blood;

  @override
  void initState() {
    super.initState();
    if (widget.employeeIndex >= 0) {
      final employee = context.read<EmployeeProvider>().allEmployees[widget.employeeIndex];
      _nameController.text = employee.name;
      _regController.text = employee.reg;
      _phoneController.text = employee.phone ?? '';
      _addressController.text = employee.address ?? '';
      _status = employee.status;
      _blood = employee.blood;
      _notesController.text = employee.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.employeeIndex >= 0 ? 'تعديل العامل' : 'إضافة عامل جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل *'),
                validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال الاسم' : null,
              ),
              TextFormField(
                controller: _regController,
                decoration: const InputDecoration(labelText: 'رقم التسجيل *'),
                validator: (value) => value?.isEmpty ?? true ? 'الرجاء إدخال رقم التسجيل' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'عنوان السكن'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'الحالة الاجتماعية'),
                items: const [
                  DropdownMenuItem(value: 'أعزب', child: Text('أعزب')),
                  DropdownMenuItem(value: 'متزوج', child: Text('متزوج')),
                  DropdownMenuItem(value: 'مطلق', child: Text('مطلق')),
                  DropdownMenuItem(value: 'أرمل', child: Text('أرمل')),
                ],
                onChanged: (value) => setState(() => _status = value),
              ),
              DropdownButtonFormField<String>(
                initialValue: _blood,
                decoration: const InputDecoration(labelText: 'زمرة الدم'),
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                ],
                onChanged: (value) => setState(() => _blood = value),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final employee = Employee(
      name: _nameController.text,
      reg: _regController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      status: _status,
      blood: _blood,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    final provider = context.read<EmployeeProvider>();
    if (widget.employeeIndex >= 0) {
      provider.updateEmployee(widget.employeeIndex, employee);
    } else {
      provider.addEmployee(employee);
    }

    Navigator.of(context).pop();
  }
}