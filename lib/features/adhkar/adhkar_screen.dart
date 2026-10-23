import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../library/favorites.dart';
import 'adhkar_data.dart';

/// Screen title for an adhkar category key (see assets/data/adhkar.json).
String adhkarTitle(BuildContext context, String category) {
  final l = AppLocalizations.of(context);
  return switch (category) {
    'morning' => l.morningAdhkar,
    'evening' => NoorFormat.tr(context, 'أذكار المساء', 'Evening adhkar'),
    'sleep' => NoorFormat.tr(context, 'أذكار النوم', 'Sleep adhkar'),
    'waking' => NoorFormat.tr(context, 'أذكار الاستيقاظ', 'Waking up'),
    'after_prayer' => NoorFormat.tr(context, 'أذكار بعد الصلاة', 'After prayer'),
    'wudu' => NoorFormat.tr(context, 'أذكار الوضوء', 'Wudu'),
    'mosque' => NoorFormat.tr(context, 'أذكار المسجد', 'The mosque'),
    'travel' => NoorFormat.tr(context, 'أذكار السفر', 'Travel'),
    'food' => NoorFormat.tr(context, 'أذكار الطعام', 'Food'),
    'home' => NoorFormat.tr(context, 'أذكار المنزل', 'Home'),
    'quran_duas' => l.catQuranDuas,
    'sunnah_duas' => l.catSunnahDuas,
    _ => category,
  };
}

class AdhkarScreen extends ConsumerStatefulWidget {
  const AdhkarScreen({super.key});
  @override
  ConsumerState<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends ConsumerState<AdhkarScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Morning adhkar until noon, evening adhkar after.
    final suggested = ref.watch(nowProvider).hour < 12 ? 'morning' : 'evening';
    final list = ref.watch(adhkarProvider(suggested)).value ?? const <Dhikr>[];
    ref.watch(dhikrSessionProvider(suggested));
    final ctrl = ref.read(dhikrSessionProvider(suggested).notifier);
    final done = list.where((d) => ctrl.remaining(d) == 0).length;

    final cats = <(IconData, String, String, bool)>[
      (Icons.wb_twilight_rounded, l.catEvening, 'evening', false),
      (Icons.dark_mode_outlined, l.catSleep, 'sleep', true),
      (Icons.wb_sunny_outlined, l.catWaking, 'waking', false),
      (Icons.mosque_outlined, l.catAfterPrayer, 'after_prayer', true),
      (Icons.water_drop_outlined, l.catWudu, 'wudu', false),
      (Icons.account_balance_outlined, l.catMosque, 'mosque', true),
      (Icons.flight_takeoff_rounded, l.catTravel, 'travel', false),
      (Icons.restaurant_outlined, l.catFood, 'food', true),
      (Icons.home_outlined, l.catHome, 'home', false),
      (Icons.menu_book_outlined, l.catQuranDuas, 'quran_duas', true),
      (Icons.receipt_long_outlined, l.catSunnahDuas, 'sunnah_duas', false),
    ].where((c) => _q.isEmpty || c.$2.contains(_q) || adhkarTitle(context, c.$3).toLowerCase().contains(_q.toLowerCase())).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          ScreenTitle(l.adhkarTitle),
          const SizedBox(height: 14),
          NoorSearchField(hint: l.searchAdhkar, onChanged: (v) => setState(() => _q = v.trim())),
          const SizedBox(height: 16),
          HeroSurface(
            radius: 28,
            onTap: () => context.push('/adhkar/session/$suggested'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: [
              Text(l.suggestedNow, style: const TextStyle(fontSize: 12, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600)),
              Text(adhkarTitle(context, suggested), style: NoorText.display(context, size: 28, color: Colors.white)),
              Row(spacing: 10, children: [
                Expanded(child: NoorProgressBar(value: list.isEmpty ? 0 : done / list.length, height: 5, color: NoorTokens.onHeroAccent, track: const Color(0x29FFFFFF))),
                Text(l.adhkarProgress(NoorFormat.digits(context, done), NoorFormat.digits(context, list.length)), style: const TextStyle(fontSize: 12, color: Color(0xD9FFFFFF))),
              ]),
            ]),
          ),
          const SizedBox(height: 18),
          SectionTitle(l.categories),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.6,
            children: [
              for (final (icon, label, key, gold) in cats)
                NoorCard(
                  radius: 20,
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.push('/adhkar/session/$key'),
                  child: Row(spacing: 12, children: [IconBadge(icon: icon, gold: gold), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)))]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class DhikrSessionScreen extends ConsumerStatefulWidget {
  const DhikrSessionScreen({super.key, required this.category});
  final String category;
  @override
  ConsumerState<DhikrSessionScreen> createState() => _DhikrSessionScreenState();
}

class _DhikrSessionScreenState extends ConsumerState<DhikrSessionScreen> {
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final list = ref.watch(adhkarProvider(widget.category)).value ?? const <Dhikr>[];
    ref.watch(dhikrSessionProvider(widget.category));
    final ctrl = ref.read(dhikrSessionProvider(widget.category).notifier);
    final done = list.where((d) => ctrl.remaining(d) == 0).length;
    final activeIndex = list.indexWhere((d) => ctrl.remaining(d) > 0);
    final ar = NoorFormat.isAr(context);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(spacing: 12, children: [
              Row(children: [
                const NoorBackButton(),
                Expanded(
                  child: Column(children: [
                    Text(adhkarTitle(context, widget.category), style: NoorText.display(context, size: 21)),
                    Text(l.adhkarProgress(NoorFormat.digits(context, done), NoorFormat.digits(context, list.length)), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
                NoorIconButton(
                  icon: Icons.translate_rounded,
                  tooltip: 'English',
                  filled: _showTranslation,
                  onPressed: () => setState(() => _showTranslation = !_showTranslation),
                ),
              ]),
              NoorProgressBar(value: list.isEmpty ? 0 : done / list.length, height: 5, color: t.gold),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              children: [
                if (list.isNotEmpty && done == list.length) ...[
                  HeroSurface(
                    radius: 24,
                    child: Column(spacing: 8, children: [
                      const EightPointStar(size: 46, color: NoorTokens.onHeroAccent, strokeWidth: 1.4, child: Icon(Icons.check_rounded, color: NoorTokens.onHeroAccent, size: 20)),
                      Text(l.completeTitle, style: NoorText.display(context, size: 24, color: Colors.white)),
                      Text(l.completeBody, style: const TextStyle(color: Color(0xD9FFFFFF))),
                      TextButton(onPressed: ctrl.reset, style: TextButton.styleFrom(foregroundColor: Colors.white), child: Text(l.restart)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
                for (var i = 0; i < list.length; i++) ...[
                  _DhikrCard(
                    dhikr: list[i],
                    position: '${NoorFormat.digits(context, i + 1)} / ${NoorFormat.digits(context, list.length)}',
                    remaining: ctrl.remaining(list[i]),
                    active: i == activeIndex,
                    showTranslation: _showTranslation,
                    source: ar ? list[i].sourceAr : list[i].sourceEn,
                    onCount: () {
                      final r = ctrl.remaining(list[i]);
                      r == 1 ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
                      ctrl.count(list[i]);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({required this.dhikr, required this.position, required this.remaining, required this.active, required this.showTranslation, required this.source, required this.onCount});
  final Dhikr dhikr;
  final String position, source;
  final int remaining;
  final bool active, showTranslation;
  final VoidCallback onCount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final done = remaining == 0;
    final repeat = dhikr.repeat == 1 ? l.once : l.times(NoorFormat.digits(context, dhikr.repeat));
    return AnimatedOpacity(
      opacity: done ? .72 : 1,
      duration: NoorMotion.enter,
      child: NoorCard(
        borderColor: active ? t.primaryLine : null,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          Row(children: [
            Expanded(child: Text(position, style: Theme.of(context).textTheme.bodySmall)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: t.goldSoft, borderRadius: BorderRadius.circular(99)),
              child: Text(repeat, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: t.goldText)),
            ),
          ]),
          Text(dhikr.ar,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(fontFamily: NoorFonts.display, fontSize: dhikr.ar.length > 200 ? 19 : 22, height: 2, color: done ? t.textSecondary : t.text)),
          if (showTranslation) Text(dhikr.en, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13, height: 1.6, color: t.textSecondary)),
          const Divider(),
          Row(children: [
            Expanded(child: Text(source, style: TextStyle(fontSize: 11.5, color: t.goldText, height: 1.5))),
            SaveButton(item: SavedItem(key: 'dhikr:${dhikr.id}', kind: 'dua', title: source, body: dhikr.ar, translation: dhikr.en, source: source), tooltip: l.save),
            if (done)
              Row(spacing: 6, children: [Icon(Icons.check_rounded, color: t.primary, size: 18), Text(l.done, style: TextStyle(color: t.primary, fontWeight: FontWeight.w600))])
            else if (active)
              Semantics(
                button: true,
                label: '${l.tap} $remaining',
                child: Material(
                  color: t.primary,
                  shape: const CircleBorder(),
                  elevation: 0,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onCount,
                    child: SizedBox.square(
                      dimension: 68,
                      child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.1, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        AnimatedSwitcher(
                          duration: context.reduceMotion ? Duration.zero : NoorMotion.press,
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                          child: Text(NoorFormat.digits(context, remaining), key: ValueKey(remaining), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.onPrimary)),
                        ),
                        Text(l.tap, style: TextStyle(fontSize: 9.5, color: t.onPrimary.withValues(alpha: .85))),
                      ])),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}
