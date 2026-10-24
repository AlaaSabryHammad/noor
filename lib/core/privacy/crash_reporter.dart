import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Where crash reports go. Collection is opt-in: nothing is sent until the
/// person agrees (see [CrashConsent]).
abstract interface class CrashReporter {
  /// False when no crash backend is configured for this build.
  bool get available;

  /// Turns collection on or off (takes effect immediately).
  Future<void> setEnabled(bool enabled);

  void recordError(Object error, StackTrace? stack, {bool fatal = false});
}

/// Used when Firebase is not configured and in tests.
class NoopCrashReporter implements CrashReporter {
  const NoopCrashReporter();
  @override
  bool get available => false;
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) {}
}

/// Overridden in `main()` once Firebase has (or has not) initialised.
final crashReporterProvider = Provider<CrashReporter>((ref) => const NoopCrashReporter());

/// The person's choice about sending anonymous crash reports:
/// `null` = not asked yet, `true` = agreed, `false` = declined.
class CrashConsent extends Notifier<bool?> {
  static const prefsKey = 'privacy.crashReports';

  @override
  bool? build() => ref.watch(sharedPreferencesProvider).getBool(prefsKey);

  Future<void> set(bool agreed) async {
    state = agreed;
    await ref.read(sharedPreferencesProvider).setBool(prefsKey, agreed);
    await ref.read(crashReporterProvider).setEnabled(agreed);
  }
}

final crashConsentProvider = NotifierProvider<CrashConsent, bool?>(CrashConsent.new);

/// Forwards uncaught Flutter and platform errors to [reporter]. The reporter
/// itself drops them unless the person has agreed. Returns a function that
/// restores the previous handlers (used by tests).
VoidCallback installErrorHooks(CrashReporter reporter) {
  final previousFlutter = FlutterError.onError;
  final previousPlatform = PlatformDispatcher.instance.onError;
  FlutterError.onError = (details) {
    previousFlutter?.call(details);
    reporter.recordError(details.exception, details.stack, fatal: true);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    reporter.recordError(error, stack, fatal: true);
    if (kDebugMode) debugPrint('Uncaught error: $error\n$stack');
    return true;
  };
  return () {
    FlutterError.onError = previousFlutter;
    PlatformDispatcher.instance.onError = previousPlatform;
  };
}
