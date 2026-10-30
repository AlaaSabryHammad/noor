import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../domain/alert_models.dart';
import '../domain/alert_planner.dart';

/// Schedules adhan alerts on the device. Behind an interface so tests and
/// unsupported platforms can substitute it.
abstract interface class NotificationScheduler {
  /// Asks the OS for permission to notify. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Replaces every pending alert with [alerts].
  Future<void> replaceAll(List<PlannedAlert> alerts);
}

/// A phone maker's "auto-start / background" screen, tried in order.
class _VendorScreen {
  const _VendorScreen(this.vendor, this.package, this.component);
  final BatteryVendor vendor;
  final String package, component;
}

const _vendorScreens = [
  _VendorScreen(BatteryVendor.huawei, 'com.huawei.systemmanager', 'com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity'),
  _VendorScreen(BatteryVendor.huawei, 'com.huawei.systemmanager', 'com.huawei.systemmanager.optimize.process.ProtectActivity'),
  _VendorScreen(BatteryVendor.honor, 'com.hihonor.systemmanager', 'com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity'),
  _VendorScreen(BatteryVendor.xiaomi, 'com.miui.securitycenter', 'com.miui.permcenter.autostart.AutoStartManagementActivity'),
  _VendorScreen(BatteryVendor.oppo, 'com.coloros.safecenter', 'com.coloros.safecenter.startupapp.StartupAppListActivity'),
  _VendorScreen(BatteryVendor.oppo, 'com.oplus.battery', 'com.oplus.powermanager.fuelgauge.PowerUsageModelActivity'),
  _VendorScreen(BatteryVendor.vivo, 'com.vivo.permissionmanager', 'com.vivo.permissionmanager.activity.BgStartUpManagerActivity'),
  _VendorScreen(BatteryVendor.samsung, 'com.samsung.android.lool', 'com.samsung.android.sm.ui.battery.BatteryActivity'),
];

class LocalNotificationScheduler implements NotificationScheduler, AlertDiagnostics {
  LocalNotificationScheduler();

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  /// One channel per sound: Android fixes a channel's sound once it exists, so
  /// changing the sound means using another channel. The "_v1" suffix lets a
  /// future change of the recording start a fresh channel too.
  static const _channelIds = {
    AdhanSound.adhan: 'adhan_alarm_v1',
    AdhanSound.adhanSoft: 'adhan_sound_v1',
    AdhanSound.tone: 'adhan_tone_v1',
    AdhanSound.silent: 'adhan_silent_v1',
  };

  static bool _hasAdhan(AdhanSound s) => s == AdhanSound.adhan || s == AdhanSound.adhanSoft;

  /// Channels of earlier builds of the app. Removed so the system settings list only the current ones.
  static const _legacyChannelIds = ['adhan_alerts', 'adhan_error', 'adhan_sound', 'adhan_test'];

  /// Not one of the planned alerts (those use 0…n), so re-planning never cancels a test in flight.
  static const _testId = 900000;

  /// File name (without extension) of `android/app/src/main/res/raw/adhan.ogg`.
  static const _androidSound = RawResourceAndroidNotificationSound('adhan');

  static String _channelName(AdhanSound s) => switch (s) {
        AdhanSound.adhan => 'Adhan on alarm volume · الأذان بصوت المنبّه',
        AdhanSound.adhanSoft => 'Adhan, follows silent mode · الأذان (يتبع وضع الصامت)',
        AdhanSound.tone => 'Prayer alerts (tone) · تنبيهات الصلاة (نغمة)',
        AdhanSound.silent => 'Prayer alerts (vibrate) · تنبيهات الصلاة (اهتزاز)',
      };

  static const _channelDescription = 'Alerts at prayer times · تنبيهات أوقات الصلاة';

  /// The alarm stream is not muted by the phone's silent mode, the notification stream is.
  static AudioAttributesUsage _usage(AdhanSound s) => s == AdhanSound.adhan ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification;

  static NotificationDetails _details(AdhanSound s) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIds[s]!,
          _channelName(s),
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: s != AdhanSound.silent,
          sound: _hasAdhan(s) ? _androidSound : null,
          audioAttributesUsage: _usage(s),
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: s != AdhanSound.silent, sound: _hasAdhan(s) ? 'adhan.caf' : null),
      );

  bool get _supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> _init() => _ready ??= _initialize();

  Future<bool> _initialize() async {
    final ok = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested explicitly when the user turns an alert on.
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestSoundPermission: false, requestBadgePermission: false),
      ),
    );
    final android = _android;
    if (android != null) {
      for (final id in _legacyChannelIds) {
        await android.deleteNotificationChannel(channelId: id);
      }
      // Created up front so the system shows them (with the right sound) before the first alert fires.
      for (final s in AdhanSound.values) {
        await android.createNotificationChannel(AndroidNotificationChannel(
          _channelIds[s]!,
          _channelName(s),
          description: _channelDescription,
          importance: Importance.max,
          playSound: s != AdhanSound.silent,
          sound: _hasAdhan(s) ? _androidSound : null,
          audioAttributesUsage: _usage(s),
          enableVibration: true,
        ));
      }
    }
    return ok ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    try {
      await _init();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _android;
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

  Future<AndroidScheduleMode> _scheduleMode() async {
    final exact = !_isAndroid || (await _android?.canScheduleExactNotifications() ?? false);
    return exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {
    if (!_supported) return;
    try {
      await _init();
      // Everything planned is replaced, but a test alert that is still counting down is left alone.
      for (final p in await _plugin.pendingNotificationRequests()) {
        if (p.id != _testId) await _plugin.cancel(id: p.id);
      }
      if (alerts.isEmpty) return;
      final mode = await _scheduleMode();
      for (final a in alerts) {
        await _plugin.zonedSchedule(
          id: a.id,
          title: a.title,
          body: a.body,
          // Absolute instant expressed in UTC, so no time-zone database is needed.
          scheduledDate: tz.TZDateTime.from(a.time, tz.UTC),
          notificationDetails: _details(a.sound),
          androidScheduleMode: mode,
        );
      }
    } catch (e) {
      debugPrint('Scheduling adhan alerts failed: $e');
    }
  }

  // ---- AlertDiagnostics -------------------------------------------------

  @override
  Future<AlertHealth> health() async {
    if (!_supported) return AlertHealth.unsupported;
    try {
      await _init();
      final pending = (await _plugin.pendingNotificationRequests()).where((p) => p.id != _testId).length;
      if (_isAndroid) {
        final android = _android;
        return AlertHealth(
          notificationsAllowed: await android?.areNotificationsEnabled() ?? true,
          exactAlarmsAllowed: await android?.canScheduleExactNotifications() ?? true,
          pending: pending,
          vendor: await _detectVendor(),
        );
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final options = await ios?.checkPermissions();
      return AlertHealth(notificationsAllowed: options?.isEnabled ?? true, pending: pending);
    } catch (e) {
      debugPrint('Alert health check failed: $e');
      return AlertHealth.unsupported;
    }
  }

  @override
  Future<bool> scheduleTest({required AdhanSound sound, required String title, required String body, Duration after = const Duration(seconds: 10)}) async {
    if (!_supported) return false;
    try {
      await _init();
      await _plugin.zonedSchedule(
        id: _testId,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(DateTime.now().add(after), tz.UTC),
        notificationDetails: _details(sound),
        androidScheduleMode: await _scheduleMode(),
      );
      return true;
    } catch (e) {
      debugPrint('Scheduling the test alert failed: $e');
      return false;
    }
  }

  @override
  Future<void> openSettings(AlertSettingsPage page) async {
    if (!_supported) return;
    try {
      await _init();
      switch (page) {
        case AlertSettingsPage.notifications:
          await _android?.openAppNotificationSettings();
        case AlertSettingsPage.exactAlarms:
          await _android?.requestExactAlarmsPermission();
        case AlertSettingsPage.battery:
          await _openBatterySettings();
      }
    } catch (e) {
      debugPrint('Opening settings failed: $e');
    }
  }

  AndroidIntent _intentOf(_VendorScreen s) => AndroidIntent(package: s.package, componentName: s.component);

  /// The maker whose background-app screen exists on this phone, if any.
  Future<BatteryVendor> _detectVendor() async {
    for (final s in _vendorScreens) {
      if (await _intentOf(s).canResolveActivity() ?? false) return s.vendor;
    }
    return BatteryVendor.other;
  }

  /// The maker's own screen when there is one; otherwise Android's battery-optimisation list, then the app's info page.
  Future<void> _openBatterySettings() async {
    if (!_isAndroid) return;
    for (final s in _vendorScreens) {
      final intent = _intentOf(s);
      if (await intent.canResolveActivity() ?? false) {
        await intent.launch();
        return;
      }
    }
    const generic = AndroidIntent(action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS');
    if (await generic.canResolveActivity() ?? false) {
      await generic.launch();
    } else {
      await _android?.openAppNotificationSettings();
    }
  }
}
