import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'service_widgets.dart';

/// Entry to the two dua collections (they reuse the adhkar session screen).
class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return ServiceScaffold(title: l.svcDuas, children: [
      NoorCard(
        color: t.primarySoft,
        borderColor: t.primaryLine,
        onTap: () => context.push('/hisn'),
        child: Row(spacing: 14, children: [
          const IconBadge(icon: Icons.auto_stories_rounded, solid: true, size: 48),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text(NoorFormat.tr(context, 'حصن المسلم كاملًا', 'Hisn al-Muslim, complete'), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              Text(NoorFormat.tr(context, '١٣٢ بابًا من أذكار اليوم والليلة وأدعية الأحوال كلها', '132 chapters: daily adhkar and supplications for every occasion'), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textSecondary),
        ]),
      ),
      const SizedBox(height: 14),
      HeroSurface(
        radius: 28,
        onTap: () => context.push('/adhkar/session/quran_duas'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
          const EightPointStar(size: 34, color: NoorTokens.onHeroAccent, strokeWidth: 1.3),
          Text(l.catQuranDuas, style: NoorText.display(context, size: 26, color: Colors.white)),
          Text(NoorFormat.tr(context, 'أدعية وردت في القرآن الكريم على ألسنة الأنبياء والصالحين', 'Supplications from the Quran, made by the prophets and the righteous'), style: const TextStyle(color: Color(0xD9FFFFFF), height: 1.6)),
        ]),
      ),
      const SizedBox(height: 14),
      NoorCard(
        onTap: () => context.push('/adhkar/session/sunnah_duas'),
        child: Row(spacing: 14, children: [
          const IconBadge(icon: Icons.receipt_long_outlined, gold: true, size: 48),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text(l.catSunnahDuas, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              Text(NoorFormat.tr(context, 'أدعية صحّت عن النبي ﷺ مع مصادرها', 'Authentic supplications of the Prophet ﷺ with their sources'), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textSecondary),
        ]),
      ),
      const SizedBox(height: 14),
      NoorCard(
        onTap: () => context.push('/adhkar/session/after_prayer'),
        child: Row(spacing: 14, children: [
          const IconBadge(icon: Icons.mosque_outlined, size: 48),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
              Text(l.catAfterPrayer, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              Text(NoorFormat.tr(context, 'التسبيح والاستغفار بعد السلام من الفريضة', 'Glorification and istighfar after the obligatory prayer'), style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: t.textSecondary),
        ]),
      ),
    ]);
  }
}
