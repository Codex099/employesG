import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import '../models/app_user.dart';

class SheetsService {
  static const String scriptUrl =
      'https://script.google.com/macros/s/AKfycbwq3hLf6ZAX6BVijaZOg0bzwP342DM96iwkboDPypItd8pfqsemvOeSb6lGpDVd5X8Z/exec';

  // ─── Employees ────────────────────────────────────────────────────────────

  Future<List<Employee>?> fetchAll() async {
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

  Future<bool> addEmployee(Employee employee) async {
    return _sendAction('add', data: employee.toMap());
  }

  Future<bool> deleteEmployee(String reg) async {
    return _sendAction('delete', reg: reg);
  }

  Future<bool> syncAll(List<Employee> employees) async {
    return _sendAction('sync_all',
        data: employees.map((e) => e.toMap()).toList());
  }

  // ─── Users (feuille "users") ──────────────────────────────────────────────

  Future<List<AppUser>?> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$scriptUrl?action=get_users'),
      );
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
    return _sendAction('delete_user', reg: username);
  }

  // ─── Notifications ────────────────────────────────────────────────────────

  /// Writes a new notification row to Google Sheets so every polling client
  /// can detect it within ~5 seconds.
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

  /// Fetches notifications with timestamp > [since] from Google Sheets.
  Future<List<Map<String, dynamic>>> fetchNotifications(int since) async {
    try {
      final response = await http.get(
        Uri.parse('$scriptUrl?action=get_notifications&since=$since'),
      );
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
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print('Error sending action $action: $e');
      return false;
    }
  }
}
