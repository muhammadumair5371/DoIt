import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final actionId = response.actionId;
        final payload = response.payload;

        if (actionId == 'action_done' && payload != null) {
          // Task marked done via notification
        } else if (actionId == 'action_snooze' && payload != null) {
          // Snooze 10 minutes
          await showNotificationNow(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: 'Snoozed Reminder',
            body: 'Task snoozed for 10 minutes.',
          );
        }
      },
    );

    _initialized = true;
  }

  Future<void> showNotificationNow({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'doit_task_channel',
      'Tasks & Reminders',
      channelDescription: 'Notifications for auto-detected tasks and reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  Future<void> scheduleTaskReminders({
    required int baseId,
    required String title,
    required DateTime dueTime,
    int leadMinutes = 30,
  }) async {
    final now = DateTime.now();
    if (dueTime.isBefore(now)) return;

    const androidDetails = AndroidNotificationDetails(
      'doit_reminders_channel',
      'Task Reminders',
      channelDescription: 'Scheduled reminders before task due dates',
      importance: Importance.max,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('action_done', 'Done', showsUserInterface: true),
        AndroidNotificationAction('action_snooze', 'Snooze 10m', showsUserInterface: true),
      ],
    );

    const details = NotificationDetails(android: androidDetails);

    // 1. Lead Time Reminder (e.g. 30 mins before due)
    final leadTime = dueTime.subtract(Duration(minutes: leadMinutes));
    if (leadTime.isAfter(now)) {
      await _notificationsPlugin.zonedSchedule(
        baseId,
        'Time to move! ⏰',
        '"$title" is due in $leadMinutes minutes.',
        tz.TZDateTime.from(leadTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // 2. Exact Due Time Reminder
    await _notificationsPlugin.zonedSchedule(
      baseId + 1,
      'Task Due Now! 🚀',
      '"$title" is due now. Chalo, abhi khatam karo!',
      tz.TZDateTime.from(dueTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelTaskReminders(int baseId) async {
    await _notificationsPlugin.cancel(baseId);
    await _notificationsPlugin.cancel(baseId + 1);
  }
}
