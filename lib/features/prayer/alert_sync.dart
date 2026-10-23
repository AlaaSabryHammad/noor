import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'data/notification_scheduler.dart';
import 'domain/alert_planner.dart';
import 'prayer_providers.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) => LocalNotificationScheduler());

const _kAsked = 'prayer.notifPermissionAsked';

/// Keeps the OS notification queue in step with the app: location, alert
/// toggles and language changes, app resume, and the first launch. Watch it
/// once near the root.
final alertSyncProvider = Provider<void>((ref) {
  var running = false, dirty = false;

  Future<void> run() async {
    if (running) {
      dirty = true;
      return;
    }
    running = true;
    try {
      do {
        dirty = false;
        if (!ref.mounted) return;
        final prefs = ref.read(sharedPreferencesProvider);
        final scheduler = ref.read(notificationSchedulerProvider);
        final enabled = ref.read(prayerAlertsProvider);
        // First launch: alerts default to on, so ask once up front.
        if (enabled.isNotEmpty && !(prefs.getBool(_kAsked) ?? false)) {
          await prefs.setBool(_kAsked, true);
          await scheduler.requestPermission();
        }
        final l = lookupAppLocalizations(Locale(ref.read(settingsProvider).locale.languageCode));
        await scheduler.replaceAll(planAlerts(
          repo: ref.read(prayerRepositoryProvider),
          location: ref.read(prayerLocationProvider),
          enabled: enabled,
          now: DateTime.now(),
          l: l,
        ));
      } while (dirty);
    } finally {
      running = false;
    }
  }

  ref.listen(prayerLocationProvider, (_, _) => run());
  ref.listen(prayerAlertsProvider, (_, _) => run());
  ref.listen(prayerRepositoryProvider, (_, _) => run()); // method or Asr rule changed
  ref.listen(settingsProvider.select((s) => s.locale), (_, _) => run());
  final lifecycle = AppLifecycleListener(onResume: run);
  ref.onDispose(lifecycle.dispose);
  Future.microtask(run);
});
