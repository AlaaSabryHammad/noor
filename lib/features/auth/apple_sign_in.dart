import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_service.dart';

/// A random string used once per request so a stolen identity token cannot be replayed.
String generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

String sha256OfString(String input) => sha256.convert(utf8.encode(input)).toString();

/// What the native Apple sheet returned, ready for Firebase.
class AppleSignInResult {
  const AppleSignInResult({required this.credential, required this.authorizationCode, this.fullName});
  final fb.OAuthCredential credential;

  /// Needed to revoke Apple’s token when the account is deleted (App Store guideline 5.1.1(v)).
  final String authorizationCode;

  /// Apple only supplies the name the first time the person signs in to the app.
  final String? fullName;
}

/// Shows the native “Sign in with Apple” sheet (iOS / macOS) and turns the
/// result into a Firebase credential. Throws [AuthFailure] for cancellation or any failure.
Future<AppleSignInResult> requestAppleCredential() async {
  final rawNonce = generateNonce();
  try {
    final apple = await SignInWithApple.getAppleIDCredential(
      scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: sha256OfString(rawNonce),
    );
    final idToken = apple.identityToken;
    if (idToken == null) throw const AuthFailure(AuthErrorKind.unknown);
    final name = [apple.givenName, apple.familyName].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    return AppleSignInResult(
      credential: fb.OAuthProvider('apple.com').credential(idToken: idToken, rawNonce: rawNonce, accessToken: apple.authorizationCode),
      authorizationCode: apple.authorizationCode,
      fullName: name.isEmpty ? null : name,
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    throw AuthFailure(e.code == AuthorizationErrorCode.canceled ? AuthErrorKind.cancelled : AuthErrorKind.unknown);
  } on SignInWithAppleNotSupportedException {
    throw const AuthFailure(AuthErrorKind.unavailable);
  } on SignInWithAppleException {
    throw const AuthFailure(AuthErrorKind.unknown);
  }
}
