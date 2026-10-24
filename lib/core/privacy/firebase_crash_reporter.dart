import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// Crashlytics-backed reporter. Collection is switched off by default (see the
/// `firebase_crashlytics_collection_enabled` entries in the native manifests)
/// and only turned on after the person agrees. Debug builds never report.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter({FirebaseCrashlytics? crashlytics}) : _c = crashlytics ?? FirebaseCrashlytics.instance;
  final FirebaseCrashlytics _c;

  @override
  bool get available => true;

  @override
  Future<void> setEnabled(bool enabled) => _c.setCrashlyticsCollectionEnabled(enabled && !kDebugMode);

  @override
  void recordError(Object error, StackTrace? stack, {bool fatal = false}) => _c.recordError(error, stack, fatal: fatal);
}
