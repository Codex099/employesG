import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sheets_service.dart';
import '../models/app_notification.dart';

/// Polls the Google Sheets "notifications" tab every [pollInterval] seconds.
/// When it finds a notification with timestamp > [_lastSeenTimestamp], it
/// fires a local device notification AND adds it to [pendingNotifications] so
/// that any listening widget can display an in-app banner.
class NotificationPollService extends ChangeNotifier {
  final SheetsService _sheets;
  final Future<void> Function(String title, String body, {int id}) _showDevice;

  /// List of notifications received since this session started.
  final List<AppNotification> pendingNotifications = [];

  /// The timestamp of the most recent notification we have already processed.
  int _lastSeenTimestamp = 0;

  static const _prefKey = 'notif_last_seen_ts';
  static const pollInterval = Duration(seconds: 5);

  Timer? _timer;
  bool _disposed = false;

  NotificationPollService({
    required SheetsService sheets,
    required Future<void> Function(String title, String body, {int id}) showDevice,
  })  : _sheets = sheets,
        _showDevice = showDevice;

  /// Must be called once after construction to restore persisted timestamp.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSeenTimestamp = prefs.getInt(_prefKey) ?? 0;

    // If this is the first run, seed the timestamp so we don't replay all
    // historical notifications from Sheets on first launch.
    if (_lastSeenTimestamp == 0) {
      _lastSeenTimestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_prefKey, _lastSeenTimestamp);
    }
  }

  /// Starts the background polling timer.
  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => _poll());
  }

  /// Stops the polling timer (call on logout / app pause).
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pushes a notification to Google Sheets (called by the user who triggered
  /// the absence event). Other devices will pick it up via polling.
  Future<void> push({
    required String type,
    required String title,
    required String message,
    required String author,
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final id = '${ts}_${author.hashCode.abs()}';

    await _sheets.pushNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      author: author,
      timestamp: ts,
    );

    // The pushing device should also advance its own cursor so it doesn't
    // receive its own notification via polling.
    _lastSeenTimestamp = ts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, _lastSeenTimestamp);
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _poll() async {
    if (_disposed) return;

    final raw = await _sheets.fetchNotifications(_lastSeenTimestamp);
    if (raw.isEmpty) return;

    int maxTs = _lastSeenTimestamp;

    for (final map in raw) {
      final notif = AppNotification.fromMap(map);
      if (notif.timestamp > _lastSeenTimestamp) {
        pendingNotifications.add(notif);
        if (notif.timestamp > maxTs) maxTs = notif.timestamp;

        // Fire local device notification (visible in status bar)
        final deviceId = notif.id.hashCode.abs() % 99000 + 1000;
        await _showDevice(notif.title, notif.message, id: deviceId);
      }
    }

    if (maxTs > _lastSeenTimestamp) {
      _lastSeenTimestamp = maxTs;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, _lastSeenTimestamp);
      if (!_disposed) notifyListeners();
    }
  }

  /// Clears all pending in-app notifications (after they've been shown).
  void clearPending() {
    pendingNotifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
