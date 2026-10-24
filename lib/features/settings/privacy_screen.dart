import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/privacy/crash_reporter.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../services/service_widgets.dart';

/// Public copy of the policy (hosted with Firebase Hosting from `site/`, see docs/RELEASE.md).
/// Point a fork at its own page with `--dart-define=PRIVACY_POLICY_URL=...`.
const privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL', defaultValue: 'https://noor-app-alaa-4829.web.app/privacy');

/// Settings → Privacy: the crash-report choice and the full policy text
/// (built from one source by `tool/build_privacy.py`).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final reporter = ref.watch(crashReporterProvider);
    final consent = ref.watch(crashConsentProvider);
    final data = ref.watch(contentJsonProvider('privacy'));

    return ServiceScaffold(title: NoorFormat.tr(context, 'الخصوصية', 'Privacy'), children: [
      if (reporter.available) ...[
        NoorCard(
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: consent == true,
            onChanged: (v) => ref.read(crashConsentProvider.notifier).set(v),
            title: Text(NoorFormat.tr(context, 'إرسال تقارير الأعطال المجهولة', 'Send anonymous crash reports'), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              NoorFormat.tr(context, 'تساعدنا على إصلاح الأعطال. لا تتضمن قراءتك ولا موقعك. متوقفة حتى توافق.', 'Helps us fix crashes. They contain no reading history or location. Off until you agree.'),
              style: TextStyle(height: 1.6, color: t.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
      contentBody(data, (d) {
        final sections = (d['sections'] as List).cast<Map<String, dynamic>>();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
          Text(NoorFormat.tr(context, 'آخر تحديث: ${d['updated']}', 'Last updated: ${d['updated']}'), style: Theme.of(context).textTheme.bodySmall),
          for (final s in sections)
            NoorCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
                Text(pick(s, 'title', ar), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                for (final p in ((ar ? s['ar'] : s['en']) as List).cast<String>())
                  Text(s['id'] == 'never' ? '•  $p' : p, style: TextStyle(height: 1.75, color: t.textSecondary, fontSize: 13.5)),
              ]),
            ),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new_rounded, size: 18),
            label: Text(NoorFormat.tr(context, 'فتح الصفحة العامة للسياسة', 'Open the public policy page')),
          ),
        ]);
      }),
    ]);
  }
}
