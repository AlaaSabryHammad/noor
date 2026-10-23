import 'dart:math' as math;

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
import 'alert_sync.dart';
import 'calc_sheet.dart';
import 'domain/prayer_method.dart';
import 'domain/prayer_models.dart';
import 'location_sheet.dart';
import 'prayer_providers.dart';

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final now = ref.watch(nowProvider);
    final day = ref.watch(prayerDayProvider);
    final loc = ref.watch(prayerLocationProvider);
    final alerts = ref.watch(prayerAlertsProvider);
    final t = context.noor;
    final next = day.next(now);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          ScreenTitle(l.prayerTitle),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: () => showLocationSheet(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, spacing: 6, children: [
                  Flexible(child: Text(NoorFormat.isAr(context) ? loc.nameAr : loc.nameEn, style: Theme.of(context).textTheme.bodySmall)),
                  Icon(Icons.expand_more_rounded, size: 16, color: t.textSecondary),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          HeroSurface(
            padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
            child: Column(children: [
              AspectRatio(
                aspectRatio: 350 / 178,
                child: CustomPaint(
                  painter: _SunPathPainter(
                    rtl: Directionality.of(context) == TextDirection.rtl,
                    fraction: _sunFraction(day, now),
                    marks: [day.timeOf(PrayerKind.dhuhr), day.timeOf(PrayerKind.asr)].map((m) => _fractionOf(day, m)).toList(),
                  ),
                  child: Align(
                    alignment: const Alignment(0, .75),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l.nextPrayer, style: const TextStyle(fontSize: 12, color: Color(0xC7FFFFFF))),
                      Text(prayerName(l, next.kind, friday: day.isFriday), style: NoorText.display(context, size: 30, color: Colors.white)),
                      Directionality(textDirection: TextDirection.ltr, child: Text(NoorFormat.countdown(next.time.difference(now)), style: NoorText.numerals(size: 20, color: NoorTokens.onHeroAccent))),
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  Text('${l.sunrise} ${NoorFormat.time(context, day.wall(day.timeOf(PrayerKind.sunrise)))}', style: const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                  const Spacer(),
                  Text('${l.maghrib} ${NoorFormat.time(context, day.wall(day.timeOf(PrayerKind.maghrib)))}', style: const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          NoorCard(
            padding: const EdgeInsets.all(6),
            child: Column(children: [
              for (final s in day.slots)
                _PrayerRow(
                  slot: s,
                  shown: day.wall(s.time),
                  isNext: s.kind == next.kind && s.time == next.time,
                  past: !s.time.isAfter(now),
                  friday: day.isFriday,
                  alertOn: alerts.contains(s.kind),
                  countdown: NoorFormat.countdown(next.time.difference(now)),
                  onToggle: () async {
                    HapticFeedback.selectionClick();
                    final turningOn = !alerts.contains(s.kind);
                    ref.read(prayerAlertsProvider.notifier).toggle(s.kind);
                    if (!turningOn) return;
                    final granted = await ref.read(notificationSchedulerProvider).requestPermission();
                    if (!granted && context.mounted) showNoorSnack(context, l.notifPermissionDenied);
                  },
                ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(spacing: 10, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: NoorCard(
                padding: const EdgeInsets.all(16),
                onTap: () => context.push('/qibla'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 10, children: [
                  Transform.rotate(angle: day.qiblaBearing * math.pi / 180, child: Icon(Icons.navigation_rounded, size: 40, color: t.gold)),
                  Text(l.qiblaDirection, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  Text(l.degFromNorth(NoorFormat.digits(context, day.qiblaBearing.round())), style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
            Expanded(
              child: NoorCard(
                padding: const EdgeInsets.all(16),
                onTap: () => showCalcSheet(context),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                  Text(l.calcMethod, style: Theme.of(context).textTheme.bodySmall),
                  Text(methodName(l, ref.watch(effectiveMethodProvider)), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  Text(ref.watch(prayerCalcProvider).madhab == AsrMadhab.hanafi ? l.asrHanafi : l.asrStandard, style: Theme.of(context).textTheme.bodySmall),
                  Text(l.calcNote, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  static double _fractionOf(PrayerDay d, DateTime t) {
    final a = d.timeOf(PrayerKind.sunrise), b = d.timeOf(PrayerKind.maghrib);
    return (t.difference(a).inSeconds / b.difference(a).inSeconds).clamp(0, 1);
  }

  static double _sunFraction(PrayerDay d, DateTime now) => _fractionOf(d, now);
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.slot, required this.shown, required this.isNext, required this.past, required this.friday, required this.alertOn, required this.countdown, required this.onToggle});
  final PrayerSlot slot;
  final DateTime shown; // slot time re-based to the location's wall clock
  final bool isNext, past, friday, alertOn;
  final String countdown;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final name = prayerName(l, slot.kind, friday: friday);
    final dim = past && !isNext;
    final note = !slot.kind.isPrayer ? l.endOfFajr : (isNext ? '${l.nextTag} · $countdown' : (past ? l.passed : ''));
    return AnimatedContainer(
      duration: NoorMotion.theme,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isNext ? t.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isNext ? t.primaryLine : Colors.transparent),
      ),
      child: Row(spacing: 12, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: isNext ? t.primary : t.sunk, borderRadius: BorderRadius.circular(13)),
          child: Icon(prayerIcon(slot.kind), size: 20, color: isNext ? t.onPrimary : (dim ? t.textSecondary : t.primary)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: dim ? t.textSecondary : t.text)),
            if (note.isNotEmpty) Text(note, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        Text(NoorFormat.time(context, shown), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: dim ? t.textSecondary : t.text)),
        if (slot.kind.isPrayer)
          IconButton(
            tooltip: alertOn ? l.alertOn(name) : l.alertOff(name),
            isSelected: alertOn,
            onPressed: onToggle,
            style: IconButton.styleFrom(backgroundColor: alertOn ? t.primarySoft : Colors.transparent, fixedSize: const Size(44, 44)),
            icon: Icon(alertOn ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, size: 19, color: alertOn ? t.primary : t.textSecondary),
          )
        else
          const SizedBox(width: 44),
      ]),
    );
  }
}

class _SunPathPainter extends CustomPainter {
  _SunPathPainter({required this.fraction, required this.marks, required this.rtl});
  final double fraction;
  final bool rtl; // sunrise starts at the reading-start edge
  final List<double> marks;

  Offset _at(Size s, double f) {
    final r = s.width * 150 / 350, cx = s.width / 2, base = s.height * 160 / 178;
    return Offset(cx - r * math.cos(math.pi * f), base - r * math.sin(math.pi * f));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (rtl) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final r = size.width * 150 / 350, cx = size.width / 2, base = size.height * 160 / 178;
    final rect = Rect.fromCircle(center: Offset(cx, base), radius: r);
    canvas.drawLine(Offset(10, base), Offset(size.width - 10, base), Paint()..color = const Color(0x2EFFFFFF));
    // dashed full arc
    final dash = Paint()
      ..color = const Color(0x38FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (double a = 0; a < math.pi; a += .06) {
      canvas.drawArc(rect, math.pi + a, .025, false, dash);
    }
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * fraction,
      false,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFC8A45D), Color(0xFFE0C486)]).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final dot = Paint()..color = const Color(0xB3FFFFFF);
    for (final m in [0.0, ...marks, 1.0]) {
      canvas.drawCircle(_at(size, m), 3, dot);
    }
    final sun = _at(size, fraction);
    canvas.drawCircle(sun, 16, Paint()..color = const Color(0x2EE0C486));
    canvas.drawCircle(sun, 8, Paint()..color = const Color(0xFFE0C486));
  }

  @override
  bool shouldRepaint(_SunPathPainter old) => old.fraction != fraction || old.rtl != rtl;
}
