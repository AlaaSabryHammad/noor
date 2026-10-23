import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/firebase_auth_service.dart';
import 'firebase_options.dart';

/// Firebase is optional: when it has not been configured (or cannot start) the
/// app runs signed-out with the account screens explaining why.
Future<AuthService> _initAuth() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return FirebaseAuthService();
  } catch (e) {
    debugPrint('Firebase not available, running without accounts: $e');
    return const DisabledAuthService();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final auth = await _initAuth();
  runApp(ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), authServiceProvider.overrideWithValue(auth)], child: const NoorApp()));
}
