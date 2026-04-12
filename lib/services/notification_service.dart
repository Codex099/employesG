import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../models/conge.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleCongeEndNotification(Conge conge) async {
    // Notification la veille de la fin du congé à 9h00 (ou la date exact pour un test si besoin)
    // Ici : on planifie la veille à 9h. Si la veille est déjà passée, on planifie immédiatement ou on passe.
    tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      DateTime(conge.dateFin.year, conge.dateFin.month, conge.dateFin.day - 1, 9, 0),
      tz.local,
    );

    // Si on est déjà le jour de la date de fin (ou passé la veille à 9h), on l'envoie tout de suite 
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    }

    final int notificationId = conge.id.hashCode;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Fin de congé demain',
      '${conge.employeeName} reprend le travail le ${DateFormat('dd/MM/yyyy').format(conge.dateFin)}',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'conge_channel_id',
          'Rappels de Congés',
          channelDescription: 'Notifications pour la fin de congés des employés',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}
