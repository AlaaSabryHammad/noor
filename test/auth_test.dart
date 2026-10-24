import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/auth/auth_service.dart';
import 'package:noor/features/auth/firebase_auth_service.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_clock.dart';

class _Noop implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

/// In-memory auth backend that behaves like Firebase for the cases we test.
class FakeAuth implements AuthService {
  FakeAuth({this.caps = const AuthCapabilities(email: true, google: true, anonymous: true)});
  final AuthCapabilities caps;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  final accounts = <String, String>{}; // email → password
  AuthErrorKind? failNext;
  int signOuts = 0;

  void _set(AppUser? u) {
    _user = u;
    _controller.add(u);
  }

  void _maybeFail() {
    final k = failNext;
    if (k != null) {
      failNext = null;
      throw AuthFailure(k);
    }
  }

  @override
  bool get available => true;
  @override
  AuthCapabilities get capabilities => caps;
  @override
  AppUser? get currentUser => _user;
  @override
  Stream<AppUser?> get userChanges => _controller.stream;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    _maybeFail();
    if (!accounts.containsKey(email) || accounts[email] != password) throw const AuthFailure(AuthErrorKind.wrongCredentials);
    _set(AppUser(uid: email, email: email, displayName: 'Alaa', providerIds: const ['password']));
  }

  @override
  Future<void> createAccount(String email, String password, {String? displayName}) async {
    _maybeFail();
    if (accounts.containsKey(email)) throw const AuthFailure(AuthErrorKind.emailInUse);
    accounts[email] = password;
    _set(AppUser(uid: email, email: email, displayName: displayName, providerIds: const ['password']));
  }

  @override
  Future<void> signInWithGoogle() async => _set(const AppUser(uid: 'g', email: 'g@x.com', displayName: 'Google User', providerIds: ['google.com']));
  @override
  Future<void> signInWithApple() async => _set(const AppUser(uid: 'a', email: 'a@privaterelay.appleid.com', displayName: 'Apple User', providerIds: ['apple.com']));
  @override
  Future<void> signInAnonymously() async => _set(const AppUser(uid: 'anon', isAnonymous: true));
  @override
  Future<void> sendPasswordReset(String email) async {
    if (!accounts.containsKey(email)) throw const AuthFailure(AuthErrorKind.userNotFound);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    _set(null);
  }

  /// Passwords this fake was asked to delete with (null = none given).
  final deleteAttempts = <String?>[];

  @override
  Future<void> deleteAccount({String? password}) async {
    deleteAttempts.add(password);
    _maybeFail();
    final u = _user;
    // Like Firebase, e-mail accounts must re-authenticate with the right password.
    if (u != null && u.usesPassword && accounts[u.email] != password) throw const AuthFailure(AuthErrorKind.wrongCredentials);
    _set(null);
  }
}

Future<(FakeAuth, ProviderContainer)> _open(WidgetTester tester, {AuthService? service}) async {
  final auth = service is FakeAuth ? service : FakeAuth();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(390 * 3, 1000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(_Noop()),
      authServiceProvider.overrideWithValue(service ?? auth),
      nowProvider.overrideWithValue(fridayMorning),
      contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
    ],
    child: const NoorApp(),
  ));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/account');
  await tester.pumpAndSettle();
  return (auth, ProviderScope.containerOf(tester.element(find.byType(NoorApp))));
}

void main() {
  group('helpers', () {
    test('email and password checks', () {
      expect(looksLikeEmail('a@b.co'), isTrue);
      expect(looksLikeEmail(' alaa@example.com '), isTrue);
      expect(looksLikeEmail('alaa@'), isFalse);
      expect(looksLikeEmail('no spaces@x.com'), isFalse);
      expect(isAcceptablePassword('12345'), isFalse);
      expect(isAcceptablePassword('123456'), isTrue);
    });

    test('Firebase error codes map to user-facing kinds', () {
      expect(kindOfCode('wrong-password'), AuthErrorKind.wrongCredentials);
      expect(kindOfCode('invalid-credential'), AuthErrorKind.wrongCredentials);
      expect(kindOfCode('email-already-in-use'), AuthErrorKind.emailInUse);
      expect(kindOfCode('network-request-failed'), AuthErrorKind.network);
      expect(kindOfCode('operation-not-allowed'), AuthErrorKind.notEnabled);
      expect(kindOfCode('something-new'), AuthErrorKind.unknown);
    });

    test('user label falls back from name to e-mail', () {
      expect(const AppUser(uid: '1', displayName: 'Sara', email: 's@x.com').label, 'Sara');
      expect(const AppUser(uid: '1', email: 'sara@x.com').label, 'sara');
      expect(const AppUser(uid: '1').label, '');
    });

    test('the disabled service refuses sign-in but signing out is a no-op', () async {
      const s = DisabledAuthService();
      expect(s.available, isFalse);
      await expectLater(s.signInAnonymously(), throwsA(isA<AuthFailure>()));
      await s.signOut();
    });
  });

  testWidgets('without Firebase the account screen explains and the app stays usable', (tester) async {
    await _open(tester, service: const DisabledAuthService());
    expect(find.textContaining('غير متاح الآن'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('create account → signed in → sign out', (tester) async {
    final (auth, _) = await _open(tester);
    await tester.tap(find.text('حساب جديد'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3)); // name, e-mail, password
    await tester.enterText(fields.at(0), 'علاء');
    await tester.enterText(fields.at(1), 'alaa@example.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pumpAndSettle();
    expect(auth.accounts['alaa@example.com'], 'secret123');
    expect(find.text('علاء'), findsOneWidget);
    expect(find.text('تسجيل الخروج'), findsOneWidget);

    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(find.text('إنشاء الحساب'), findsOneWidget); // back on the form, still in create mode
  });

  testWidgets('bad input is rejected before the network; backend errors are shown in words', (tester) async {
    final (auth, _) = await _open(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'not-an-email');
    await tester.enterText(fields.at(1), 'abc');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('البريد الإلكتروني غير صالح.'), findsOneWidget);

    await tester.enterText(fields.at(0), 'who@example.com');
    await tester.enterText(fields.at(1), 'wrongpass');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsOneWidget);

    auth.failNext = AuthErrorKind.network;
    auth.accounts['who@example.com'] = 'wrongpass';
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر الاتصال'), findsOneWidget);
  });

  testWidgets('guest and Google sign-in; Google is hidden when the build cannot offer it', (tester) async {
    final (auth, _) = await _open(tester);
    expect(find.textContaining('Google'), findsOneWidget);
    await tester.tap(find.text('المتابعة كزائر'));
    await tester.pumpAndSettle();
    expect(find.text('زائر'), findsOneWidget);
    expect(auth.currentUser!.isAnonymous, isTrue);
  });

  testWidgets('only the methods the build supports are offered', (tester) async {
    await _open(tester, service: FakeAuth(caps: const AuthCapabilities(email: true)));
    expect(find.textContaining('Google'), findsNothing);
    expect(find.text('المتابعة كزائر'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('Sign in with Apple is hidden when the build cannot offer it', (tester) async {
    await _open(tester);
    expect(find.text('المتابعة باستخدام Apple'), findsNothing);
  });

  testWidgets('Sign in with Apple button signs in', (tester) async {
    final (auth, _) = await _open(tester, service: FakeAuth(caps: const AuthCapabilities(email: true, google: true, apple: true)));
    expect(find.text('المتابعة باستخدام Apple'), findsOneWidget);
    await tester.tap(find.text('المتابعة باستخدام Apple'));
    await tester.pumpAndSettle();
    expect(auth.currentUser!.providerIds, ['apple.com']);
    expect(find.text('Apple User'), findsOneWidget);
  });

  group('account deletion', () {
    testWidgets('an e-mail account must confirm with its password; a wrong one keeps the account', (tester) async {
      final (auth, _) = await _open(tester);
      auth.accounts['a@b.co'] = 'secret123';
      await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
      await tester.enterText(find.byType(TextField).at(1), 'secret123');
      await tester.tap(find.text('دخول'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();
      expect(find.text('حذف الحساب نهائيًا؟'), findsOneWidget);
      final delete = find.widgetWithText(FilledButton, 'حذف');
      expect(tester.widget<FilledButton>(delete).onPressed, isNull, reason: 'cannot delete before typing the password');

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNotNull);
      expect(find.text('البريد أو كلمة المرور غير صحيحة.'), findsOneWidget);

      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'secret123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(auth.deleteAttempts, ['wrong', 'secret123']);
    });

    testWidgets('Google accounts are deleted without asking for a password', (tester) async {
      final (auth, _) = await _open(tester);
      await tester.tap(find.textContaining('Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'حذف'));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNull);
      expect(auth.deleteAttempts, [null]);
    });

    testWidgets('cancelling leaves the account alone', (tester) async {
      final (auth, _) = await _open(tester);
      await tester.tap(find.textContaining('Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(auth.currentUser, isNotNull);
      expect(auth.deleteAttempts, isEmpty);
    });
  });

  testWidgets('the account screen links to the privacy policy', (tester) async {
    await _open(tester);
    await tester.ensureVisible(find.text('سياسة الخصوصية'));
    await tester.tap(find.text('سياسة الخصوصية'));
    await tester.pumpAndSettle();
    expect(find.text('الخصوصية'), findsWidgets);
    expect(find.text('ملخص'), findsOneWidget);
  });

  testWidgets('forgot password asks for a valid e-mail first, then confirms', (tester) async {
    final (auth, _) = await _open(tester);
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    expect(find.textContaining('اكتب بريدك أولًا'), findsOneWidget);

    auth.accounts['a@b.co'] = 'x';
    await tester.enterText(find.byType(TextField).at(0), 'a@b.co');
    await tester.tap(find.text('نسيت كلمة المرور؟'));
    await tester.pumpAndSettle();
    expect(find.textContaining('أرسلنا رابط إعادة التعيين'), findsOneWidget);
  });
}
