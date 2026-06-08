import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../models/absence.dart';
import '../models/app_user.dart';
import 'package:get/get.dart';
import 'connectivity_service.dart';

class SheetsService extends GetxService {
  final String scriptUrl =
      'https://script.google.com/macros/s/AKfycbwq3hLf6ZAX6BVijaZOg0bzwP342DM96iwkboDPypItd8pfqsemvOeSb6lGpDVd5X8Z/exec';

  Future<String?> fetchConfigLastModified() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=get_config_last_modified'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['lastModified']?.toString();
      }
    } catch (_) {}
    return null;
  }

  // ─── Employees ────────────────────────────────────────────────────────────

  Future<List<Employee>?> fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse(scriptUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Employee.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
    return null;
  }

  Future<bool> addEmployeeRaw(Map<String, dynamic> data) async {
    return _sendAction('add_employee', data: data);
  }

  Future<bool> updateEmployeeRaw(String reg, Map<String, dynamic> data) async {
    return _sendAction('update_employee', payload: {'id': reg, 'data': data});
  }

  Future<bool> deleteEmployee(String reg) async {
    return _sendAction('delete_employee', payload: {'reg': reg});
  }

  // ─── Absences ─────────────────────────────────────────────────────────────

  Future<List<Absence>?> fetchAbsences() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=get_absences'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => Absence.fromMap(e)).toList();
      }
    } catch (e) {
      print('Error fetching absences: $e');
    }
    return null;
  }

  Future<bool> addAbsenceRaw(Map<String, dynamic> data) async {
    return _sendAction('add_absence', data: data);
  }

  Future<bool> updateAbsenceRaw(String id, Map<String, dynamic> data) async {
    return _sendAction('update_absence', payload: {'id': id, 'data': data});
  }

  Future<bool> deleteAbsence(String id) async {
    return _sendAction('delete_absence', payload: {'id': id});
  }

  // ─── Users (feuille "users") ──────────────────────────────────────────────

  Future<List<AppUser>?> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=get_users'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map((e) => AppUser.fromMap(e)).toList();
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return null;
  }

  Future<bool> addUser(AppUser user) async {
    return _sendAction('add_user', data: user.toMap());
  }

  Future<bool> updateUser(AppUser user) async {
    return _sendAction('update_user', data: user.toMap());
  }

  Future<bool> deleteUser(String username) async {
    return _sendAction('delete_user', payload: {'username': username});
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  Future<bool> pushNotification({
    required String id,
    required String type,
    required String title,
    required String message,
    required String author,
    required int timestamp,
  }) async {
    return _sendAction('add_notification', data: {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'author': author,
      'timestamp': timestamp,
    });
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(int since) async {
    try {
      final response = await http.get(Uri.parse('$scriptUrl?action=get_notifications&since=$since'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
    return [];
  }

  // ─── Generic ──────────────────────────────────────────────────────────────

  Future<bool> _sendAction(String action, {dynamic data, Map<String, dynamic>? payload}) async {
    try {
      final bodyMap = payload ?? {};
      bodyMap['action'] = action;
      if (data != null) {
        bodyMap['data'] = data;
      }
      
      final response = await http.post(
        Uri.parse(scriptUrl),
        body: json.encode(bodyMap),
      );
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print('Error sending action $action: $e');
      return false;
    }
  }
}
