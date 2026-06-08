import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'pending_queue_service.dart';
import 'sheets_service.dart';

class ConnectivityService extends GetxService {
  static const _forceOfflineKey = 'forceOfflineMode';
  late final Box _settingsBox;

  final isOnline = false.obs;
  final isForceOffline = false.obs;

  @override
  void onInit() {
    super.onInit();
    _settingsBox = Hive.box('settings');
    isForceOffline.value = _settingsBox.get(_forceOfflineKey, defaultValue: false);
    
    _startListening();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    // In connectivity_plus > 5.0.0, checkConnectivity might return List<ConnectivityResult>.
    // Usually result.contains(ConnectivityResult.none) is the check if it's a list.
    // If it's a single result:
    await _updateOnlineStatus(result is List ? (result as List).first : result);
  }

  void _startListening() {
    Connectivity().onConnectivityChanged.listen((result) {
      _updateOnlineStatus(result is List ? (result as List).first : result);
    });
  }

  Future<void> _updateOnlineStatus(dynamic result) async {
    if (isForceOffline.value) {
      isOnline.value = false;
      return;
    }
    
    // Check if network is theoretically present
    final hasNetwork = result != ConnectivityResult.none;
    
    if (hasNetwork) {
      // Real ping
      isOnline.value = await _pingBackend();
    } else {
      isOnline.value = false;
    }

    if (isOnline.value) {
      try {
         await Get.find<PendingQueueService>().flush();
      } catch (_) {}
    }
  }

  Future<void> toggleForceOffline() async {
    isForceOffline.value = !isForceOffline.value;
    await _settingsBox.put(_forceOfflineKey, isForceOffline.value);
    
    final result = await Connectivity().checkConnectivity();
    await _updateOnlineStatus(result is List ? (result as List).first : result);
  }

  Future<bool> _pingBackend() async {
    try {
      // If AppConfig.baseUrl isn't defined, use SheetsUrl directly.
      // We will define it in sheets_service or config.
      final url = Get.find<SheetsService>().scriptUrl; 
      final response = await http.get(Uri.parse('$url?action=ping')).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static bool get isConnected => Get.find<ConnectivityService>().isOnline.value;
}


