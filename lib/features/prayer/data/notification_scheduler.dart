import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/alert_planner.dart';

/// Schedules adhan alerts on the device. Behind an interface so tests and
/// unsupported platforms can substitute it.
abstract interface class NotificationScheduler {
  /// Asks the OS for permission to notify. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Replaces every pending alert with [alerts].
  Future<void> replaceAll(List<PlannedAlert> alerts);
}

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler();

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static const _channelId = 'adhan_alerts';
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Prayer alerts · تنبيهات الصلاة',
      channelDescription: 'Adhan alerts at prayer times · تنبيهات أوقات الصلاة',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  bool get _supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  Future<bool> _init() => _ready ??= _plugin
          .initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              // Permission is requested explicitly when the user turns an alert on.
              iOS: DarwinInitializationSettings(requestAlertPermission: false, requestSoundPermission: false, requestBadgePermission: false),
            ),
          )
          .then((ok) => ok ?? false);

  @override
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      await _init();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await android?.requestNotificationsPermission() ?? false;
        if (granted && !(await android?.canScheduleExactNotifications() ?? true)) {
          // Opens the system "alarms & reminders" screen; without it alerts still
          // arrive, but Android may delay them by a few minutes.
          await android?.requestExactAlarmsPermission();
        }
        return granted;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('Notification permission failed: $e');
      return false;
    }
  }

  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {
    if (!_supported) return;
    try {
      await _init();
      await _plugin.cancelAllPendingNotifications();
      if (alerts.isEmpty) return;
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final exact = defaultTargetPlatform != TargetPlatform.android || (await android?.canScheduleExactNotifications() ?? false);
      for (final a in alerts) {
        await _plugin.zonedSchedule(
          id: a.id,
          title: a.title,
          body: a.body,
          // Absolute instant expressed in UTC, so no time-zone database is needed.
          scheduledDate: tz.TZDateTime.from(a.time, tz.UTC),
          notificationDetails: _details,
          androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (e) {
      debugPrint('Scheduling adhan alerts failed: $e');
    }
  }
}
