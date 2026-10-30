/// What plays when a prayer alert fires.
enum AdhanSound {
  /// The bundled adhan recording on the *alarm* volume (Android), so it is
  /// heard even when the phone is on silent.
  adhan,

  /// The same recording on the notification volume: follows the phone's silent mode.
  adhanSoft,

  /// The phone's normal notification tone.
  tone,

  /// Vibration only.
  silent,
}

/// Phone makers whose battery managers stop background apps (and cancel
/// their alarms) unless the person allows it. [other] covers stock Android.
enum BatteryVendor { huawei, honor, xiaomi, oppo, vivo, samsung, other }

/// Which system screen to open.
enum AlertSettingsPage { notifications, exactAlarms, battery }

/// A snapshot of everything that decides whether an alert will really ring.
class AlertHealth {
  const AlertHealth({this.supported = true, this.notificationsAllowed = true, this.exactAlarmsAllowed = true, this.pending = 0, this.vendor = BatteryVendor.other});

  /// False on platforms (web, desktop) and builds without local notifications.
  final bool supported;
  final bool notificationsAllowed, exactAlarmsAllowed;

  /// Alerts currently waiting in the system scheduler.
  final int pending;
  final BatteryVendor vendor;

  static const unsupported = AlertHealth(supported: false);
}

/// Self-check, test alert and settings shortcuts behind the alert card. Kept
/// apart from the scheduler so tests and unsupported platforms stay trivial.
abstract interface class AlertDiagnostics {
  Future<AlertHealth> health();

  /// Schedules a one-off alert [after] a few seconds through the same path as
  /// the real ones. Returns whether it was scheduled.
  Future<bool> scheduleTest({required AdhanSound sound, required String title, required String body, Duration after});

  Future<void> openSettings(AlertSettingsPage page);
}

class NoopAlertDiagnostics implements AlertDiagnostics {
  const NoopAlertDiagnostics();
  @override
  Future<AlertHealth> health() async => AlertHealth.unsupported;
  @override
  Future<bool> scheduleTest({required AdhanSound sound, required String title, required String body, Duration after = const Duration(seconds: 10)}) async => false;
  @override
  Future<void> openSettings(AlertSettingsPage page) async {}
}
