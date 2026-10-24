import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/privacy/crash_reporter.dart';
import 'core/privacy/firebase_crash_reporter.dart';
import 'core/providers.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/firebase_auth_service.dart';
import 'firebase_options.dart';

/// Firebase is optional: when it has not been configured (or cannot start) the
/// app runs signed-out, without crash reporting, and the account screens explain why.
Future<(AuthService, CrashReporter)> _initFirebase(SharedPreferences prefs) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase not available, running without accounts: $e');
    return (const DisabledAuthService(), const NoopCrashReporter());
  }
  final crash = FirebaseCrashReporter();
  try {
    // Off unless the person agreed on a previous run.
    await crash.setEnabled(prefs.getBool(CrashConsent.prefsKey) ?? false);
  } catch (e) {
    debugPrint('Crash reporting unavailable: $e');
    return (FirebaseAuthService(), const NoopCrashReporter());
  }
  return (FirebaseAuthService(), crash);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final (auth, crash) = await _initFirebase(prefs);
  installErrorHooks(crash);
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authServiceProvider.overrideWithValue(auth),
      crashReporterProvider.overrideWithValue(crash),
    ],
    child: const NoorApp(),
  ));
}
