import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/privacy/crash_reporter.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';

/// One-time question on the home screen: may NOOR send anonymous crash
/// reports? Shown only when a crash backend exists and nothing was decided yet;
/// the choice can be changed later in Settings → Privacy.
class CrashConsentCard extends ConsumerWidget {
  const CrashConsentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(crashReporterProvider.select((r) => r.available));
    final decided = ref.watch(crashConsentProvider) != null;
    if (!available || decided) return const SizedBox.shrink();
    final t = context.noor;
    final ctrl = ref.read(crashConsentProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NoorCard(
        color: t.goldSoft,
        borderColor: t.goldLine,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
          Row(spacing: 10, children: [
            Icon(Icons.bug_report_outlined, color: t.goldText),
            Expanded(child: Text(NoorFormat.tr(context, 'ساعدنا على تحسين نور', 'Help us improve NOOR'), style: TextStyle(fontWeight: FontWeight.w700, color: t.goldText))),
          ]),
          Text(
            NoorFormat.tr(context, 'هل تسمح بإرسال تقارير أعطال مجهولة؟ لا تتضمن قراءتك ولا موقعك، ويمكنك تغيير اختيارك في أي وقت من الإعدادات.', 'May NOOR send anonymous crash reports? They contain no reading history or location, and you can change your mind any time in Settings.'),
            style: TextStyle(height: 1.7, color: t.goldText, fontSize: 13.5),
          ),
          Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            FilledButton(onPressed: () => ctrl.set(true), child: Text(NoorFormat.tr(context, 'أوافق', 'Allow'))),
            TextButton(onPressed: () => ctrl.set(false), child: Text(NoorFormat.tr(context, 'لا، شكرًا', 'No thanks'))),
            TextButton(onPressed: () => context.push('/privacy'), child: Text(NoorFormat.tr(context, 'التفاصيل', 'Details'))),
          ]),
        ]),
      ),
    );
  }
}
