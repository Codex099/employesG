import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/employee.dart';
import '../services/sync_service.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _regController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _workplaceController;
  late TextEditingController _notesController;
  
  String _selectedStatus = '';
  String _selectedBlood = '';
  int _childrenCount = 0;

  final List<String> _statusOptions = ['أعزب', 'متزوج', 'مطلق', 'أرمل'];
  final List<String> _bloodOptions = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameController = TextEditingController(text: e?.name ?? '');
    _regController = TextEditingController(text: e?.reg ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _addressController = TextEditingController(text: e?.address ?? '');
    _workplaceController = TextEditingController(text: e?.workplace ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _selectedStatus = e?.status ?? '';
    _selectedBlood = e?.blood ?? '';
    _childrenCount = e?.children ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'تعديل بيانات العامل' : 'إضافة عامل جديد'),
          backgroundColor: const Color(0xFF2563eb),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('الاسم الكامل *', _nameController, Icons.person, (v) => v!.isEmpty ? 'الرجاء إدخال الاسم' : null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('رقم التسجيل *', _regController, Icons.badge, (v) => v!.isEmpty ? 'الرجاء إدخال الرقم' : null, keyboardType: TextInputType.phone),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown('زمرة الدم', _bloodOptions, _selectedBlood, (v) => setState(() => _selectedBlood = v!)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('رقم الهاتف', _phoneController, Icons.phone, null, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField('عنوان السكن', _addressController, Icons.home, null),
                const SizedBox(height: 16),
                _buildTextField('مكان العمل', _workplaceController, Icons.work, null),
                const SizedBox(height: 16),
                _buildDropdown('الحالة الاجتماعية', _statusOptions, _selectedStatus, (v) => setState(() => _selectedStatus = v!)),
                if (_selectedStatus != 'أعزب' && _selectedStatus.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildChildrenStepper(),
                ],
                const SizedBox(height: 16),
                _buildTextField('ملاحظات', _notesController, Icons.note, null, maxLines: 3),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563eb),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                    ),
                    child: Text(
                      isEdit ? 'حفظ التعديلات' : 'إضافة العامل',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String? Function(String?)? validator, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF2563eb)),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, String current, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current.isEmpty ? null : current,
              hint: const Text('اختر'),
              isExpanded: true,
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('عدد الأولاد', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () => setState(() => _childrenCount++), icon: const Icon(Icons.add_circle_outline, color: Colors.green)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('$_childrenCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: () => setState(() => _childrenCount = _childrenCount > 0 ? _childrenCount - 1 : 0), icon: const Icon(Icons.remove_circle_outline, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final employee = Employee(
        name: _nameController.text,
        reg: _regController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        status: _selectedStatus,
        blood: _selectedBlood,
        workplace: _workplaceController.text,
        children: _childrenCount,
        notes: _notesController.text,
        created: widget.employee?.created ?? DateTime.now().millisecondsSinceEpoch,
      );

      final syncService = Provider.of<SyncService>(context, listen: false);
      if (widget.employee != null) {
        syncService.updateEmployee(employee);
      } else {
        syncService.addEmployee(employee);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.employee != null ? 'تم تحديث البيانات' : 'تمت إضافة العامل')),
      );
    }
  }
}
