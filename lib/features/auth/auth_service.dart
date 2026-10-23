import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in person, independent of the auth backend.
@immutable
class AppUser {
  const AppUser({required this.uid, this.displayName, this.email, this.photoUrl, this.isAnonymous = false});
  final String uid;
  final String? displayName, email, photoUrl;
  final bool isAnonymous;

  /// Name to show: display name, else the part of the e-mail before “@”.
  String get label {
    final n = displayName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final e = email;
    if (e != null && e.contains('@')) return e.split('@').first;
    return '';
  }

  @override
  bool operator ==(Object other) => other is AppUser && other.uid == uid && other.displayName == displayName && other.email == email && other.photoUrl == photoUrl && other.isAnonymous == isAnonymous;

  @override
  int get hashCode => Object.hash(uid, displayName, email, photoUrl, isAnonymous);
}

enum AuthErrorKind { invalidEmail, wrongCredentials, userNotFound, emailInUse, weakPassword, network, tooManyRequests, disabled, notEnabled, requiresRecentLogin, cancelled, unavailable, unknown }

/// A failure the UI can explain; never carries raw backend messages.
class AuthFailure implements Exception {
  const AuthFailure(this.kind);
  final AuthErrorKind kind;
  @override
  String toString() => 'AuthFailure($kind)';
}

/// Which sign-in methods the running build can offer.
@immutable
class AuthCapabilities {
  const AuthCapabilities({this.email = false, this.google = false, this.anonymous = false});
  final bool email, google, anonymous;
  bool get any => email || google || anonymous;
}

abstract interface class AuthService {
  /// False when Firebase is not configured for this build (no options file).
  bool get available;
  AuthCapabilities get capabilities;
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;

  Future<void> signInWithEmail(String email, String password);
  Future<void> createAccount(String email, String password, {String? displayName});
  Future<void> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();

  /// Permanently deletes the account (App Store / Play requirement for apps
  /// that offer account creation).
  Future<void> deleteAccount();
}

/// Used when Firebase has not been configured: the app works fully signed out.
class DisabledAuthService implements AuthService {
  const DisabledAuthService();
  @override
  bool get available => false;
  @override
  AuthCapabilities get capabilities => const AuthCapabilities();
  @override
  AppUser? get currentUser => null;
  @override
  Stream<AppUser?> get userChanges => Stream.value(null);

  Never _no() => throw const AuthFailure(AuthErrorKind.unavailable);
  @override
  Future<void> signInWithEmail(String email, String password) async => _no();
  @override
  Future<void> createAccount(String email, String password, {String? displayName}) async => _no();
  @override
  Future<void> signInWithGoogle() async => _no();
  @override
  Future<void> signInAnonymously() async => _no();
  @override
  Future<void> sendPasswordReset(String email) async => _no();
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async => _no();
}

/// Overridden in `main()` once Firebase has (or has not) initialised.
final authServiceProvider = Provider<AuthService>((ref) => const DisabledAuthService());

final authUserProvider = StreamProvider<AppUser?>((ref) async* {
  final s = ref.watch(authServiceProvider);
  yield s.currentUser;
  yield* s.userChanges;
});

/// Basic client-side checks so obvious mistakes never reach the network.
bool looksLikeEmail(String s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(s.trim());
bool isAcceptablePassword(String s) => s.length >= 6;
