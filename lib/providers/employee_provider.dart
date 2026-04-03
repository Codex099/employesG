import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/employee.dart';

class EmployeeProvider with ChangeNotifier {
  late Box<Employee> _employeeBox;
  List<Employee> _employees = [];
  List<Employee> get allEmployees => _employees;
  String _searchQuery = '';

  List<Employee> get employees {
    if (_searchQuery.isEmpty) return _employees;
    return _employees.where((e) =>
      e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e.reg.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (e.phone?.contains(_searchQuery) ?? false)
    ).toList();
  }

  int get totalEmployees => _employees.length;
  int get marriedCount => _employees.where((e) => e.status == 'متزوج').length;
  int get singleCount => _employees.where((e) => e.status == 'أعزب').length;
  int get withPhoneCount => _employees.where((e) => e.phone != null && e.phone!.isNotEmpty).length;

  Future<void> init() async {
    _employeeBox = await Hive.openBox<Employee>('employees');
    _employees = _employeeBox.values.toList();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addEmployee(Employee employee) async {
    await _employeeBox.add(employee);
    _employees.add(employee);
    notifyListeners();
  }

  Future<void> updateEmployee(int index, Employee employee) async {
    final key = _employeeBox.keyAt(index);
    await _employeeBox.put(key, employee);
    _employees[index] = employee;
    notifyListeners();
  }

  Future<void> deleteEmployee(int index) async {
    final key = _employeeBox.keyAt(index);
    await _employeeBox.delete(key);
    _employees.removeAt(index);
    notifyListeners();
  }

  Future<void> importEmployees(List<Employee> employees) async {
    await _employeeBox.clear();
    for (var emp in employees) {
      await _employeeBox.add(emp);
    }
    _employees = employees;
    notifyListeners();
  }
}