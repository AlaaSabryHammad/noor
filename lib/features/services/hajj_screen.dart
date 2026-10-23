import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'service_widgets.dart';

class HajjScreen extends ConsumerStatefulWidget {
  const HajjScreen({super.key});
  @override
  ConsumerState<HajjScreen> createState() => _HajjScreenState();
}

class _HajjScreenState extends ConsumerState<HajjScreen> {
  String _kind = 'hajj';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final now = ref.watch(nowProvider);
    final offset = ref.watch(settingsProvider.select((s) => s.hijriOffset));
    final h = NoorFormat.hijri(now, offsetDays: offset);
    // 8 Dhul-Hijjah of this Hijri year, or of the next if it has passed.
    final cal = HijriCalendar();
    var year = h.hYear;
    var start = cal.hijriToGregorian(year, 12, 8);
    final today = DateTime(now.year, now.month, now.day);
    if (DateTime(start.year, start.month, start.day).isBefore(today.subtract(const Duration(days: 6)))) {
      year++;
      start = cal.hijriToGregorian(year, 12, 8);
    }
    final daysLeft = DateTime(start.year, start.month, start.day).difference(today).inDays;
    final data = ref.watch(contentJsonProvider('hajj'));

    return ServiceScaffold(title: l.svcHajj, children: [
      HeroSurface(
        radius: 28,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text(NoorFormat.tr(context, 'موسم الحج ${NoorFormat.digits(context, year)} هـ', 'Hajj season $year AH'), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600)),
              Text(daysLeft > 0 ? NoorFormat.tr(context, 'بعد ${NoorFormat.digits(context, daysLeft)} يومًا', 'In $daysLeft days') : NoorFormat.tr(context, 'موسم الحج الآن', 'Hajj is underway'), style: NoorText.display(context, size: 30, color: Colors.white)),
              Text('${NoorFormat.digits(context, start.day)} ${NoorFormat.gregMonth(context, start.month)} ${NoorFormat.digits(context, start.year)} (${NoorFormat.tr(context, 'التروية', 'Tarwiyah')})', style: const TextStyle(color: Color(0xD9FFFFFF), fontSize: 13)),
            ]),
          ),
          const EightPointStar(size: 52, color: NoorTokens.onHeroAccent, strokeWidth: 1.4),
        ]),
      ),
      const SizedBox(height: 14),
      NoorSegmented<String>(values: const ['hajj', 'umrah'], labels: [NoorFormat.tr(context, 'مناسك الحج', 'Hajj rites'), NoorFormat.tr(context, 'مناسك العمرة', 'Umrah rites')], selected: _kind, onChanged: (v) => setState(() => _kind = v)),
      const SizedBox(height: 14),
      contentBody(data, (d) {
        final steps = (d['steps'] as List).cast<Map<String, dynamic>>().where((s) => s['kind'] == _kind).toList();
        return Column(spacing: 10, children: [
          for (var i = 0; i < steps.length; i++)
            NoorCard(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
                Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(11)), child: Text(NoorFormat.digits(context, i + 1), style: TextStyle(fontWeight: FontWeight.w700, color: t.primary))),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                    Text(pick(steps[i], 'title', ar), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(pick(steps[i], 'body', ar), style: TextStyle(height: 1.8, color: t.textSecondary, fontSize: 13.5)),
                  ]),
                ),
              ]),
            ),
        ]);
      }),
      const SizedBox(height: 14),
      Text(NoorFormat.tr(context, 'ملخص للتعلّم. اتبع إرشادات حملتك وعلمائك في تفاصيل المناسك.', 'A learning summary. Follow your group and scholars for the details of the rites.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
