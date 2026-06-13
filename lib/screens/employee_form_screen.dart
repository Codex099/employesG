import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';
import '../models/employee.dart';
import '../services/sync_service.dart';
import '../utils/translations.dart';

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

    return Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'edit_employee'.tr(context) : 'new_employee'.tr(context)),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('full_name'.tr(context) + ' *', _nameController, Icons.person, (v) => v!.isEmpty ? 'required'.tr(context) : null),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('reg_number'.tr(context), _regController, Icons.badge, (v) => v!.isEmpty ? 'required'.tr(context) : null, keyboardType: TextInputType.phone),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown('blood_type'.tr(context), _bloodOptions, _selectedBlood, (v) => setState(() => _selectedBlood = v!)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('phone_number'.tr(context), _phoneController, Icons.phone, null, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField('address'.tr(context), _addressController, Icons.home, null),
                const SizedBox(height: 16),
                
                // Workplace Dropdown
                GetBuilder<SyncService>(builder: (syncService) {
                  final workplaces = syncService.workplaces.map((w) => w.name).toList();
                  final List<String> options = workplaces.toList();
                  if (_workplaceController.text.isNotEmpty && !options.contains(_workplaceController.text)) {
                    options.insert(0, _workplaceController.text);
                  }
                  return _buildDropdown('workplace'.tr(context), options, _workplaceController.text, (v) {
                    setState(() => _workplaceController.text = v ?? '');
                  });
                }),
                const SizedBox(height: 16),
                _buildDropdown('family_status'.tr(context), _statusOptions, _selectedStatus, (v) => setState(() => _selectedStatus = v!)),
                if (_selectedStatus != 'أعزب' && _selectedStatus.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildChildrenStepper(),
                ],
                const SizedBox(height: 16),
                _buildTextField('observations'.tr(context), _notesController, Icons.note, null, maxLines: 3),
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
                      isEdit ? 'save'.tr(context) : 'new_employee'.tr(context),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            filled: true,
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current.isEmpty ? null : current,
              hint: Text('select'.tr(context)),
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
        Text('children_count'.tr(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
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
              IconButton(onPressed: () => setState(() => _childrenCount++), icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('$_childrenCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(onPressed: () => setState(() => _childrenCount = _childrenCount > 0 ? _childrenCount - 1 : 0), icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.error)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
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
        updatedAt: DateTime.now().toIso8601String(),
        version: (widget.employee?.version ?? 0) + 1,
      );

      final syncService = Get.find<SyncService>();
      try {
        if (widget.employee != null) {
          await syncService.updateEmployee(employee);
        } else {
          await syncService.addEmployee(employee);
        }

        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          final message = 'saved_successfully'.tr(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final messenger = ScaffoldMessenger.of(context);
          final message = 'error_occurred'.tr(context);
          messenger.showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
