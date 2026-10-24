import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart' show SignInWithAppleButton, SignInWithAppleButtonStyle;

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../services/service_widgets.dart';
import 'auth_service.dart';

String authErrorMessage(BuildContext c, AuthErrorKind k) => switch (k) {
      AuthErrorKind.invalidEmail => NoorFormat.tr(c, 'البريد الإلكتروني غير صالح.', 'That e-mail address is not valid.'),
      AuthErrorKind.wrongCredentials => NoorFormat.tr(c, 'البريد أو كلمة المرور غير صحيحة.', 'The e-mail or password is incorrect.'),
      AuthErrorKind.userNotFound => NoorFormat.tr(c, 'لا يوجد حساب بهذا البريد.', 'No account uses this e-mail.'),
      AuthErrorKind.emailInUse => NoorFormat.tr(c, 'هذا البريد مسجّل بالفعل. جرّب تسجيل الدخول.', 'This e-mail is already registered. Try signing in.'),
      AuthErrorKind.weakPassword => NoorFormat.tr(c, 'كلمة المرور ضعيفة: استخدم ٦ أحرف على الأقل.', 'Password is too weak: use at least 6 characters.'),
      AuthErrorKind.network => NoorFormat.tr(c, 'تعذّر الاتصال. تحقق من الإنترنت.', 'Couldn’t connect. Check your internet connection.'),
      AuthErrorKind.tooManyRequests => NoorFormat.tr(c, 'محاولات كثيرة. حاول لاحقًا.', 'Too many attempts. Try again later.'),
      AuthErrorKind.disabled => NoorFormat.tr(c, 'تم إيقاف هذا الحساب.', 'This account has been disabled.'),
      AuthErrorKind.notEnabled => NoorFormat.tr(c, 'طريقة الدخول هذه غير مفعّلة بعد.', 'This sign-in method is not enabled yet.'),
      AuthErrorKind.requiresRecentLogin => NoorFormat.tr(c, 'لأمان حسابك، سجّل الدخول من جديد ثم أعد المحاولة.', 'For your security, sign in again and retry.'),
      AuthErrorKind.cancelled => NoorFormat.tr(c, 'أُلغيت العملية.', 'Cancelled.'),
      AuthErrorKind.unavailable => NoorFormat.tr(c, 'الحسابات غير متاحة في هذا الإصدار.', 'Accounts are not available in this build.'),
      AuthErrorKind.unknown => NoorFormat.tr(c, 'حدث خطأ غير متوقع. حاول مرة أخرى.', 'Something went wrong. Please try again.'),
    };

/// Asks for confirmation before deleting the account. For e-mail accounts it
/// also asks for the current password, which Firebase needs to re-authenticate
/// before it will delete anything. Pops the password ('' when none is needed),
/// or null when cancelled.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.askPassword});
  final bool askPassword;
  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = !widget.askPassword || _password.text.isNotEmpty;
    return AlertDialog(
      title: Text(NoorFormat.tr(context, 'حذف الحساب نهائيًا؟', 'Delete your account permanently?')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
        Text(NoorFormat.tr(context, 'سيُحذف حسابك وبيانات الدخول المرتبطة به ولا يمكن التراجع. تبقى بياناتك المحلية على هذا الجهاز حتى تمسح بيانات التطبيق.', 'Your account and its sign-in data will be deleted and this cannot be undone. Data stored on this device stays until you clear the app’s data.')),
        if (widget.askPassword)
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: NoorFormat.tr(context, 'كلمة المرور الحالية', 'Current password')),
          ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(NoorFormat.tr(context, 'إلغاء', 'Cancel'))),
        FilledButton(
          onPressed: canDelete ? () => Navigator.of(context).pop(widget.askPassword ? _password.text : '') : null,
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB23A1E)),
          child: Text(NoorFormat.tr(context, 'حذف', 'Delete')),
        ),
      ],
    );
  }
}

class _PrivacyLink extends StatelessWidget {
  const _PrivacyLink();
  @override
  Widget build(BuildContext context) => Center(child: TextButton(onPressed: () => context.push('/privacy'), child: Text(NoorFormat.tr(context, 'سياسة الخصوصية', 'Privacy policy'))));
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _name = TextEditingController(), _email = TextEditingController(), _password = TextEditingController();
  bool _creating = false, _busy = false, _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Runs an auth action, showing progress and any failure in place.
  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted && success != null) showNoorSnack(context, success);
    } on AuthFailure catch (e) {
      if (mounted && e.kind != AuthErrorKind.cancelled) setState(() => _error = authErrorMessage(context, e.kind));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _submit(AuthService auth) {
    final email = _email.text.trim(), pw = _password.text;
    if (!looksLikeEmail(email)) return setState(() => _error = authErrorMessage(context, AuthErrorKind.invalidEmail));
    if (!isAcceptablePassword(pw)) return setState(() => _error = authErrorMessage(context, _creating ? AuthErrorKind.weakPassword : AuthErrorKind.wrongCredentials));
    _run(() => _creating ? auth.createAccount(email, pw, displayName: _name.text) : auth.signInWithEmail(email, pw));
  }

  Future<void> _confirmDelete(AuthService auth, AppUser user) async {
    // null = cancelled; otherwise the password to re-authenticate with ('' when none is needed).
    final result = await showDialog<String>(context: context, builder: (_) => DeleteAccountDialog(askPassword: user.usesPassword));
    if (!mounted || result == null) return;
    await _run(() => auth.deleteAccount(password: result.isEmpty ? null : result), success: NoorFormat.tr(context, 'تم حذف الحساب', 'Account deleted'));
  }

  InputDecoration _decoration(String label, {Widget? suffix}) {
    final t = context.noor;
    return InputDecoration(
      labelText: label,
      suffixIcon: suffix,
      filled: true,
      fillColor: t.surface,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: t.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: t.primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final auth = ref.watch(authServiceProvider);
    final user = ref.watch(authUserProvider).value;
    final title = NoorFormat.tr(context, 'حسابي', 'My account');

    if (!auth.available) {
      return ServiceScaffold(title: title, children: [
        NoorCard(
          color: t.goldSoft,
          borderColor: t.goldLine,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Icon(Icons.cloud_off_rounded, color: t.goldText),
            Text(NoorFormat.tr(context, 'تسجيل الدخول غير متاح الآن', 'Sign-in is not available right now'), style: TextStyle(fontWeight: FontWeight.w700, color: t.goldText)),
            Text(NoorFormat.tr(context, 'يعمل التطبيق كاملًا دون حساب. ستظهر خيارات الحساب عند تفعيل الخدمة في هذا الإصدار.', 'The app works fully without an account. Account options appear once the service is enabled in this build.'), style: TextStyle(height: 1.7, color: t.goldText)),
          ]),
        ),
      ]);
    }

    if (user != null) {
      return ServiceScaffold(title: title, children: [
        HeroSurface(
          radius: 28,
          child: Column(spacing: 10, children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0x24FFFFFF),
              backgroundImage: user.photoUrl == null ? null : NetworkImage(user.photoUrl!),
              child: user.photoUrl != null ? null : (user.isAnonymous ? const Icon(Icons.person_outline_rounded, size: 34, color: Colors.white) : Text(user.label.isEmpty ? '؟' : user.label.characters.first.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            Text(user.isAnonymous ? NoorFormat.tr(context, 'زائر', 'Guest') : user.label, style: NoorText.display(context, size: 26, color: Colors.white)),
            if (user.email != null) Text(user.email!, style: const TextStyle(color: Color(0xD9FFFFFF))),
          ]),
        ),
        const SizedBox(height: 16),
        if (user.isAnonymous)
          NoorCard(
            color: t.goldSoft,
            borderColor: t.goldLine,
            child: Text(NoorFormat.tr(context, 'أنت تتصفح كزائر. سجّل الخروج ثم أنشئ حسابًا لتحتفظ بهويتك على أجهزتك.', 'You are browsing as a guest. Sign out, then create an account to keep your identity across devices.'), style: TextStyle(height: 1.7, color: t.goldText)),
          ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: Color(0xFFB23A1E)))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _busy ? null : () => _run(auth.signOut), icon: const Icon(Icons.logout_rounded), label: Text(NoorFormat.tr(context, 'تسجيل الخروج', 'Sign out'))),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : () => _confirmDelete(auth, user),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFB23A1E)),
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(NoorFormat.tr(context, 'حذف الحساب', 'Delete account')),
        ),
        const _PrivacyLink(),
      ]);
    }

    final caps = auth.capabilities;
    return ServiceScaffold(title: title, children: [
      NoorSegmented<bool>(values: const [false, true], labels: [NoorFormat.tr(context, 'تسجيل الدخول', 'Sign in'), NoorFormat.tr(context, 'حساب جديد', 'Create account')], selected: _creating, onChanged: (v) => setState(() {
            _creating = v;
            _error = null;
          })),
      const SizedBox(height: 16),
      if (caps.email) ...[
        if (_creating) ...[
          TextField(controller: _name, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.name], decoration: _decoration(NoorFormat.tr(context, 'الاسم (اختياري)', 'Name (optional)'))),
          const SizedBox(height: 10),
        ],
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.email], decoration: _decoration(NoorFormat.tr(context, 'البريد الإلكتروني', 'E-mail'))),
        const SizedBox(height: 10),
        TextField(
          controller: _password,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          autofillHints: [_creating ? AutofillHints.newPassword : AutofillHints.password],
          onSubmitted: (_) => _submit(auth),
          decoration: _decoration(NoorFormat.tr(context, 'كلمة المرور', 'Password'), suffix: IconButton(tooltip: NoorFormat.tr(context, 'إظهار/إخفاء', 'Show / hide'), icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _showPassword = !_showPassword))),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Color(0xFFB23A1E), height: 1.5))),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : () => _submit(auth),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm))),
          child: _busy ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4)) : Text(_creating ? NoorFormat.tr(context, 'إنشاء الحساب', 'Create account') : NoorFormat.tr(context, 'دخول', 'Sign in')),
        ),
        if (!_creating)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      final email = _email.text.trim();
                      if (!looksLikeEmail(email)) return setState(() => _error = NoorFormat.tr(context, 'اكتب بريدك أولًا ثم اضغط «نسيت كلمة المرور».', 'Enter your e-mail first, then tap “Forgot password”.'));
                      _run(() => auth.sendPasswordReset(email), success: NoorFormat.tr(context, 'أرسلنا رابط إعادة التعيين إلى بريدك', 'We sent a reset link to your e-mail'));
                    },
              child: Text(NoorFormat.tr(context, 'نسيت كلمة المرور؟', 'Forgot password?')),
            ),
          ),
      ],
      if (caps.google || caps.apple || caps.anonymous) ...[
        const SizedBox(height: 8),
        Row(spacing: 12, children: [const Expanded(child: Divider()), Text(NoorFormat.tr(context, 'أو', 'or'), style: TextStyle(color: t.textSecondary)), const Expanded(child: Divider())]),
        const SizedBox(height: 14),
      ],
      if (caps.apple) ...[
        SignInWithAppleButton(
          onPressed: _busy ? null : () => _run(auth.signInWithApple),
          text: NoorFormat.tr(context, 'المتابعة باستخدام Apple', 'Continue with Apple'),
          height: 50,
          style: Theme.of(context).brightness == Brightness.dark ? SignInWithAppleButtonStyle.white : SignInWithAppleButtonStyle.black,
          borderRadius: BorderRadius.circular(NoorRadius.sm),
        ),
        const SizedBox(height: 10),
      ],
      if (caps.google)
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
          label: Text(NoorFormat.tr(context, 'المتابعة باستخدام Google', 'Continue with Google')),
        ),
      if (caps.anonymous) ...[
        const SizedBox(height: 10),
        TextButton(onPressed: _busy ? null : () => _run(auth.signInAnonymously), child: Text(NoorFormat.tr(context, 'المتابعة كزائر', 'Continue as a guest'))),
      ],
      const SizedBox(height: 16),
      Text(NoorFormat.tr(context, 'الحساب اختياري: كل ميزات التطبيق تعمل دونه.', 'An account is optional: every feature works without one.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      const _PrivacyLink(),
    ]);
  }
}
