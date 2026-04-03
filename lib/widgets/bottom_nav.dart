import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../providers/employee_provider.dart';
import '../models/employee.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'تصدير',
          ),
          const SizedBox(), // Space for FAB
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _importData,
            tooltip: 'استيراد',
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final provider = context.read<EmployeeProvider>();
    final employees = provider.allEmployees;

    if (employees.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات للتصدير')),
        );
      }
      return;
    }

    final json = jsonEncode(employees.map((e) => {
      'name': e.name,
      'reg': e.reg,
      'phone': e.phone,
      'address': e.address,
      'status': e.status,
      'blood': e.blood,
      'notes': e.notes,
      'created': e.created.toIso8601String(),
    }).toList());

    final fileName = 'عمال_${DateTime.now().toIso8601String().split('T')[0]}.json';
    await Share.shareXFiles([
      XFile.fromData(
        utf8.encode(json),
        name: fileName,
        mimeType: 'application/json',
      ),
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تصدير ${employees.length} سجل')),
      );
    }
  }

  Future<void> _importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      try {
        final data = jsonDecode(content) as List;
        final employees = data.map((e) => Employee(
          name: e['name'],
          reg: e['reg'],
          phone: e['phone'],
          address: e['address'],
          status: e['status'],
          blood: e['blood'],
          notes: e['notes'],
          created: DateTime.parse(e['created']),
        )).toList();

        await context.read<EmployeeProvider>().importEmployees(employees);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم استيراد ${employees.length} عامل')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خطأ في قراءة الملف')),
          );
        }
      }
    }
  }
}