import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// OAuth *web* client id of the Firebase project (needed by Google Sign-In on
/// Android to obtain an ID token). Pass it at build time:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

AppUser? _map(fb.User? u) => u == null ? null : AppUser(uid: u.uid, displayName: u.displayName, email: u.email, photoUrl: u.photoURL, isAnonymous: u.isAnonymous);

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
  AuthCapabilities get capabilities => AuthCapabilities(email: true, anonymous: true, google: googleServerClientId.isNotEmpty && GoogleSignIn.instance.supportsAuthenticate());

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

  @override
  Future<void> signInWithGoogle() => _guard(() async {
        _googleInit ??= GoogleSignIn.instance.initialize(serverClientId: googleServerClientId.isEmpty ? null : googleServerClientId);
        await _googleInit;
        try {
          final account = await GoogleSignIn.instance.authenticate();
          final idToken = account.authentication.idToken;
          if (idToken == null) throw const AuthFailure(AuthErrorKind.unknown);
          await _auth.signInWithCredential(fb.GoogleAuthProvider.credential(idToken: idToken));
        } on GoogleSignInException catch (e) {
          throw AuthFailure(e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted ? AuthErrorKind.cancelled : AuthErrorKind.unknown);
        }
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
  Future<void> deleteAccount() => _guard(() async {
        final u = _auth.currentUser;
        if (u == null) return;
        await u.delete();
      });
}
