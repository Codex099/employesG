import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';

class StorageService {
  static const String _keyEmployees = 'employees';
  static const String _keySyncQueue = 'sync_queue';
  static const String _keyThemeMode = 'theme_mode';

  // --- Employees ---

  Future<void> saveEmployees(List<Employee> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(employees.map((e) => e.toMap()).toList());
    await prefs.setString(_keyEmployees, encoded);
  }

  Future<List<Employee>> loadEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encoded = prefs.getString(_keyEmployees);
    if (encoded == null) return [];
    
    final List<dynamic> decoded = json.decode(encoded);
    return decoded.map((item) => Employee.fromMap(item)).toList();
  }

  // --- Sync Queue (For offline changes) ---
  // Store actions that need to be sent to Google Sheets when back online
  
  Future<void> addToSyncQueue(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_keySyncQueue) ?? [];
    queue.add(json.encode(action));
    await prefs.setStringList(_keySyncQueue, queue);
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList(_keySyncQueue) ?? [];
    return queue.map((e) => json.decode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySyncQueue);
  }

  // --- Theme ---

  Future<void> saveThemeMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyThemeMode, isDarkMode);
  }

  Future<bool> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyThemeMode) ?? false;
  }

  // --- Generic Bool ---

  Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> loadBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  // --- Generic String ---

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
