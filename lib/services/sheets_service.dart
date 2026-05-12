import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';

class SheetsService {
  // TODO: The user must provide their SCRIPT_URL
  static const String scriptUrl = 'https://script.google.com/macros/s/AKfycbz4_oNLi4lv-_OaBP5te3-QUY05aCCKyA0SkJtIUteJWx25xK0cfYy07Z4J_yTHyBU/exec';

  Future<List<Employee>> fetchAll() async {
    try {
      final response = await http.get(Uri.parse(scriptUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Employee.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching from Sheets: $e');
    }
    return [];
  }

  Future<bool> addEmployee(Employee employee) async {
    return _sendAction('add', data: employee.toMap());
  }

  Future<bool> deleteEmployee(String reg) async {
    return _sendAction('delete', reg: reg);
  }

  Future<bool> syncAll(List<Employee> employees) async {
    return _sendAction('sync_all', data: employees.map((e) => e.toMap()).toList());
  }

  Future<bool> _sendAction(String action, {dynamic data, String? reg}) async {
    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: json.encode({
          'action': action,
          if (data != null) 'data': data,
          if (reg != null) 'reg': reg,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 302; // 302 is common for Apps Script redirects
    } catch (e) {
      print('Error sending action $action to Sheets: $e');
      return false;
    }
  }
}
