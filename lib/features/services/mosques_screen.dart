import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../prayer/location_sheet.dart';
import '../prayer/prayer_providers.dart';
import 'service_widgets.dart';

/// Maps search link for mosques around a point. Works in any maps app/browser.
Uri mosqueSearchUri(double lat, double lng) => Uri.https('www.google.com', '/maps/search/mosque/@${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)},15z');

class MosquesScreen extends ConsumerWidget {
  const MosquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final loc = ref.watch(prayerLocationProvider);
    final ar = NoorFormat.isAr(context);

    return ServiceScaffold(title: l.svcMosques, children: [
      HeroSurface(
        radius: 28,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
          const EightPointStar(size: 38, color: NoorTokens.onHeroAccent, strokeWidth: 1.4),
          Text(NoorFormat.tr(context, 'المساجد حول', 'Mosques around'), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600)),
          Text(ar ? loc.nameAr : loc.nameEn, style: NoorText.display(context, size: 24, color: Colors.white)),
          Text(NoorFormat.tr(context, 'تُفتح الخريطة في تطبيق الخرائط على جهازك.', 'The map opens in your device’s maps app.'), style: const TextStyle(color: Color(0xD9FFFFFF))),
        ]),
      ),
      const SizedBox(height: 14),
      NoorPrimaryButton(
        label: NoorFormat.tr(context, 'ابحث عن المساجد القريبة', 'Find nearby mosques'),
        onPressed: () async {
          final ok = await launchUrl(mosqueSearchUri(loc.latitude, loc.longitude), mode: LaunchMode.externalApplication);
          if (!ok && context.mounted) showNoorSnack(context, NoorFormat.tr(context, 'تعذّر فتح الخرائط على هذا الجهاز.', 'Couldn’t open a maps app on this device.'));
        },
      ),
      const SizedBox(height: 10),
      Row(spacing: 10, children: [
        Expanded(
          child: NoorCard(
            padding: const EdgeInsets.all(14),
            onTap: () => showLocationSheet(context),
            child: Column(spacing: 6, children: [Icon(Icons.my_location_rounded, color: t.primary), Text(l.changeLocation, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))]),
          ),
        ),
        Expanded(
          child: NoorCard(
            padding: const EdgeInsets.all(14),
            onTap: () => context.push('/qibla'),
            child: Column(spacing: 6, children: [Icon(Icons.explore_outlined, color: t.gold), Text(l.qiblaTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))]),
          ),
        ),
      ]),
      const SizedBox(height: 14),
      NoorCard(
        color: t.goldSoft,
        borderColor: t.goldLine,
        padding: const EdgeInsets.all(14),
        child: Text(
          NoorFormat.tr(context, 'للبحث الدقيق اجعل موقعك من «موقعي الحالي» بدل المدينة المختارة.', 'For a precise search, set your location to “My location” instead of a listed city.'),
          style: TextStyle(fontSize: 12.5, height: 1.7, color: t.goldText),
        ),
      ),
    ]);
  }
}
