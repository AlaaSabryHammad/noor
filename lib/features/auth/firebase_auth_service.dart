import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'apple_sign_in.dart';
import 'auth_service.dart';

/// OAuth *web* client id of the Firebase project "noor-app-alaa-4829" (Google
/// Sign-In needs it on Android to obtain an ID token). It is a public
/// identifier, not a secret. Point a fork at its own project with:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '849515368017-r16cjtsm34a5568u75iki9stf21ujf8f.apps.googleusercontent.com');

AppUser? _map(fb.User? u) => u == null
    ? null
    : AppUser(uid: u.uid, displayName: u.displayName, email: u.email, photoUrl: u.photoURL, isAnonymous: u.isAnonymous, providerIds: [for (final p in u.providerData) p.providerId]);

/// “Sign in with Apple” is offered on Apple platforms only (App Store guideline 4.8 applies there).
bool get appleSignInSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

AuthErrorKind kindOfCode(String code) => switch (code) {
      'invalid-email' => AuthErrorKind.invalidEmail,
      'wrong-password' || 'invalid-credential' || 'invalid-login-credentials' => AuthErrorKind.wrongCredentials,
      'user-not-found' => AuthErrorKind.userNotFound,
      'email-already-in-use' || 'credential-already-in-use' => AuthErrorKind.emailInUse,
      'weak-password' => AuthErrorKind.weakPassword,
      'network-request-failed' => AuthErrorKind.network,
      'too-many-requests' => AuthErrorKind.tooManyRequests,
      'user-disabled' => AuthErrorKind.disabled,
      'operation-not-allowed' => AuthErrorKind.notEnabled,
      'requires-recent-login' => AuthErrorKind.requiresRecentLogin,
      _ => AuthErrorKind.unknown,
    };

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth}) : _auth = auth ?? fb.FirebaseAuth.instance;
  final fb.FirebaseAuth _auth;
  Future<void>? _googleInit;

  @override
  bool get available => true;

  @override
  AuthCapabilities get capabilities => AuthCapabilities(email: true, anonymous: true, apple: appleSignInSupported, google: googleServerClientId.isNotEmpty && GoogleSignIn.instance.supportsAuthenticate());

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _auth.userChanges().map(_map);

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthFailure(kindOfCode(e.code));
    } on AuthFailure {
      rethrow;
    }
  }

  @override
  Future<void> signInWithEmail(String email, String password) => _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<void> createAccount(String email, String password, {String? displayName}) => _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        final name = displayName?.trim();
        if (name != null && name.isNotEmpty) await cred.user?.updateDisplayName(name);
      });

  /// Shows Google’s account picker and returns a Firebase credential for it.
  Future<fb.AuthCredential> _googleCredential() async {
    _googleInit ??= GoogleSignIn.instance.initialize(serverClientId: googleServerClientId.isEmpty ? null : googleServerClientId);
    await _googleInit;
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthFailure(AuthErrorKind.unknown);
      return fb.GoogleAuthProvider.credential(idToken: idToken);
    } on GoogleSignInException catch (e) {
      throw AuthFailure(e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted ? AuthErrorKind.cancelled : AuthErrorKind.unknown);
    }
  }

  @override
  Future<void> signInWithGoogle() => _guard(() async => _auth.signInWithCredential(await _googleCredential()));

  @override
  Future<void> signInWithApple() => _guard(() async {
        final apple = await requestAppleCredential();
        final cred = await _auth.signInWithCredential(apple.credential);
        final user = cred.user;
        // Apple sends the name only on the very first sign-in: keep it.
        if (user != null && (user.displayName ?? '').isEmpty && apple.fullName != null) await user.updateDisplayName(apple.fullName);
      });

  @override
  Future<void> signInAnonymously() => _guard(_auth.signInAnonymously);

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {/* not signed in with Google */}
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount({String? password}) => _guard(() async {
        final u = _auth.currentUser;
        if (u == null) return;
        final providers = {for (final p in u.providerData) p.providerId};
        if (providers.contains('apple.com')) {
          // Apple requires its token to be revoked when the account is deleted, and
          // that needs a fresh authorization code, so ask Apple again first.
          final apple = await requestAppleCredential();
          await u.reauthenticateWithCredential(apple.credential);
          await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
          await u.delete();
          return;
        }
        try {
          await u.delete();
        } on fb.FirebaseAuthException catch (e) {
          if (e.code != 'requires-recent-login') rethrow;
          await _reauthenticate(u, providers, password);
          await u.delete();
        }
      });

  /// Proves it is still the same person (Firebase insists before deleting an old session).
  Future<void> _reauthenticate(fb.User u, Set<String> providers, String? password) async {
    if (providers.contains('password')) {
      final email = u.email;
      if (email == null || password == null || password.isEmpty) throw const AuthFailure(AuthErrorKind.requiresRecentLogin);
      await u.reauthenticateWithCredential(fb.EmailAuthProvider.credential(email: email, password: password));
    } else if (providers.contains('google.com')) {
      await u.reauthenticateWithCredential(await _googleCredential());
    } else {
      throw const AuthFailure(AuthErrorKind.requiresRecentLogin);
    }
  }
}
