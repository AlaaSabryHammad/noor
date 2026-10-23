import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'prayer_providers.dart';

/// Device heading source. The app ships a simulated source; wire
/// `flutter_compass` (or sensors_plus + magnetometer fusion) for production
/// and expose its accuracy so the UI can ask for calibration.
final headingProvider = NotifierProvider<HeadingController, double>(HeadingController.new);

class HeadingController extends Notifier<double> {
  @override
  double build() => 212;
  void set(double v) => state = v % 360;
}

class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final bearing = ref.watch(prayerDayProvider).qiblaBearing;
    final heading = ref.watch(headingProvider);
    final diff = ((bearing - heading + 540) % 360) - 180;
    final aligned = diff.abs() <= 4;
    final status = aligned ? l.facingQibla : (diff > 0 ? l.turnRight(NoorFormat.digits(context, diff.abs().round())) : l.turnLeft(NoorFormat.digits(context, diff.abs().round())));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Row(children: [const NoorBackButton(), Expanded(child: Center(child: ScreenTitle(l.qiblaTitle, size: 22))), const SizedBox(width: 44)]),
            const SizedBox(height: 14),
            Center(
              child: AnimatedContainer(
                duration: NoorMotion.enter,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: aligned ? t.primary : t.goldSoft, borderRadius: BorderRadius.circular(99)),
                child: Semantics(
                  liveRegion: true,
                  child: Text(status, style: TextStyle(fontWeight: FontWeight.w600, color: aligned ? t.onPrimary : t.goldText)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AspectRatio(
              aspectRatio: 1,
              child: Stack(alignment: Alignment.center, children: [
                Positioned(top: 0, child: Icon(Icons.arrow_drop_down_rounded, size: 40, color: aligned ? t.primary : t.gold)),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: t.surface, border: Border.all(color: t.border), boxShadow: t.cardShadow),
                    child: AnimatedRotation(
                      turns: -heading / 360,
                      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 500),
                      curve: NoorMotion.curve,
                      child: CustomPaint(
                        painter: _RosePainter(t: t, bearing: bearing, labels: NoorFormat.isAr(context) ? const ['ش', 'ق', 'ج', 'غ'] : const ['N', 'E', 'S', 'W']),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Directionality(textDirection: TextDirection.ltr, child: Text('${heading.round()}°', style: NoorText.numerals(size: 34, color: t.text, weight: FontWeight.w700))),
                    Text(l.deviceHeading, style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            NoorCard(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l.qiblaDirection}: ${l.degFromNorth(NoorFormat.digits(context, bearing.round()))}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(l.simulateHeading, style: Theme.of(context).textTheme.bodySmall),
                Slider(
                  value: heading,
                  max: 359,
                  label: '${heading.round()}°',
                  onChanged: (v) {
                    final wasAligned = aligned;
                    ref.read(headingProvider.notifier).set(v);
                    final nd = ((bearing - v + 540) % 360) - 180;
                    if (!wasAligned && nd.abs() <= 4) HapticFeedback.mediumImpact();
                  },
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Text(l.calibrationHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RosePainter extends CustomPainter {
  _RosePainter({required this.t, required this.bearing, required this.labels});
  final NoorTokens t;
  final double bearing;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final minor = Paint()
      ..color = t.borderStrong
      ..strokeWidth = 1;
    final major = Paint()
      ..color = t.textSecondary
      ..strokeWidth = 1.6;
    for (var d = 0; d < 360; d += 5) {
      final a = d * math.pi / 180;
      final big = d % 30 == 0;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * (r - 8), c + dir * (r - (big ? 22 : 15)), big ? major : minor);
    }
    canvas.drawCircle(c, r * .42, Paint()..color = t.primarySoft);
    final qa = bearing * math.pi / 180;
    final qDir = Offset(math.sin(qa), -math.cos(qa));
    final kaaba = c + qDir * r * .7;
    canvas.drawLine(c, kaaba, Paint()
      ..color = t.gold
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round);
    // Kaaba glyph: black cube with gold band (kiswah).
    canvas.save();
    canvas.translate(kaaba.dx, kaaba.dy);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -13, 26, 26), const Radius.circular(3)), Paint()..color = const Color(0xFF172B28));
    canvas.drawRect(const Rect.fromLTWH(-13, -7, 26, 4), Paint()..color = const Color(0xFFC8A45D));
    canvas.restore();
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(fontFamily: NoorFonts.arabicUi, fontSize: i == 0 ? 15 : 13, fontWeight: FontWeight.w700, color: i == 0 ? const Color(0xFFC2410C) : t.textSecondary)),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = c + Offset(math.sin(a), -math.cos(a)) * (r - 38);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RosePainter old) => old.t != t || old.bearing != bearing || old.labels != labels;
}
