import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';

const tasbeehPhrases = ['سُبْحَانَ اللَّهِ', 'الْحَمْدُ لِلَّهِ', 'اللَّهُ أَكْبَرُ', 'لَا إِلَٰهَ إِلَّا اللَّهُ', 'أَسْتَغْفِرُ اللَّهَ'];

@immutable
class TasbeehState {
  const TasbeehState({this.count = 0, this.phrase = 0, this.target = 33, this.today = 0, this.total = 0});
  final int count, phrase, target, today, total;
  TasbeehState copyWith({int? count, int? phrase, int? target, int? today, int? total}) =>
      TasbeehState(count: count ?? this.count, phrase: phrase ?? this.phrase, target: target ?? this.target, today: today ?? this.today, total: total ?? this.total);
}

class TasbeehController extends Notifier<TasbeehState> {
  String get _todayKey {
    final d = ref.read(nowProvider);
    return 'tasbeeh.today.${d.year}-${d.month}-${d.day}';
  }

  @override
  TasbeehState build() {
    final p = ref.watch(sharedPreferencesProvider);
    return TasbeehState(
      count: p.getInt('tasbeeh.count') ?? 0,
      phrase: p.getInt('tasbeeh.phrase') ?? 0,
      target: p.getInt('tasbeeh.target') ?? 33,
      today: p.getInt(_todayKey) ?? 0,
      total: p.getInt('tasbeeh.total') ?? 0,
    );
  }

  /// Returns true when this tap completed a cycle.
  bool tap() {
    final s = state;
    final next = s.count >= s.target ? 1 : s.count + 1;
    state = s.copyWith(count: next, today: s.today + 1, total: s.total + 1);
    _save();
    return next == s.target;
  }

  void setPhrase(int i) {
    state = state.copyWith(phrase: i, count: 0);
    _save();
  }

  void setTarget(int t) {
    state = state.copyWith(target: t, count: math.min(state.count, t));
    _save();
  }

  void reset() {
    state = state.copyWith(count: 0);
    _save();
  }

  void _save() {
    ref.read(sharedPreferencesProvider)
      ..setInt('tasbeeh.count', state.count)
      ..setInt('tasbeeh.phrase', state.phrase)
      ..setInt('tasbeeh.target', state.target)
      ..setInt(_todayKey, state.today)
      ..setInt('tasbeeh.total', state.total);
  }
}

final tasbeehProvider = NotifierProvider<TasbeehController, TasbeehState>(TasbeehController.new);

class TasbeehScreen extends ConsumerWidget {
  const TasbeehScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final s = ref.watch(tasbeehProvider);
    final ctrl = ref.read(tasbeehProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: ColumnListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            Row(children: [const NoorBackButton(), Expanded(child: Center(child: ScreenTitle(l.tasbeehTitle, size: 22))), const SizedBox(width: 44)]),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tasbeehPhrases.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ChoiceChip(
                  label: Text(tasbeehPhrases[i], style: const TextStyle(fontFamily: NoorFonts.display, fontSize: 15)),
                  selected: s.phrase == i,
                  onSelected: (_) => ctrl.setPhrase(i),
                  selectedColor: t.primary,
                  labelStyle: TextStyle(color: s.phrase == i ? t.onPrimary : t.text),
                  showCheckmark: false,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: s.phrase == i ? t.primary : t.border),
                  backgroundColor: t.surface,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(tasbeehPhrases[s.phrase], textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: NoorText.display(context, size: 30)),
            const SizedBox(height: 12),
            Center(
              child: Semantics(
                button: true,
                label: '${l.tapToCount} ${s.count}',
                child: GestureDetector(
                  onTap: () {
                    final cycle = ctrl.tap();
                    if (cycle) {
                      HapticFeedback.heavyImpact();
                      showNoorSnack(context, l.cycleComplete);
                    } else {
                      HapticFeedback.selectionClick();
                    }
                  },
                  child: SizedBox.square(
                    dimension: 290,
                    child: CustomPaint(
                      painter: _BeadsPainter(lit: (33 * math.min(1, s.count / s.target)).round(), t: t),
                      child: Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(NoorFormat.digits(context, s.count), style: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: t.text, height: 1)),
                          Text(l.ofTarget(NoorFormat.digits(context, s.target)), style: Theme.of(context).textTheme.bodySmall),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 240,
                child: NoorSegmented<int>(values: const [33, 99, 100], labels: [for (final n in [33, 99, 100]) NoorFormat.digits(context, n)], selected: s.target, onChanged: ctrl.setTarget),
              ),
            ),
            const SizedBox(height: 16),
            Row(spacing: 10, children: [
              Expanded(child: _Stat(value: NoorFormat.digits(context, s.today), label: l.today)),
              Expanded(child: _Stat(value: NoorFormat.digits(context, s.total), label: l.allTime)),
              Expanded(
                child: NoorCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onTap: ctrl.reset,
                  child: Column(spacing: 4, children: [Icon(Icons.restart_alt_rounded, color: t.text), Text(l.reset, style: Theme.of(context).textTheme.bodySmall)]),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => NoorCard(
        radius: 20,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(spacing: 2, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), Text(label, style: Theme.of(context).textTheme.bodySmall)]),
      );
}

class _BeadsPainter extends CustomPainter {
  _BeadsPainter({required this.lit, required this.t});
  final int lit;
  final NoorTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 118 / 290;
    canvas.drawCircle(c, size.width * 96 / 290, Paint()..color = t.surface);
    canvas.drawCircle(c, size.width * 96 / 290, Paint()
      ..color = t.border
      ..style = PaintingStyle.stroke);
    canvas.drawCircle(c, size.width * 80 / 290, Paint()..color = t.primarySoft);
    for (var i = 0; i < 33; i++) {
      final a = i / 33 * 2 * math.pi;
      final p = c + Offset(math.sin(a), -math.cos(a)) * r;
      final on = i < lit;
      final current = i == lit - 1;
      canvas.drawCircle(p, current ? 10 : 6, Paint()..color = current ? t.gold : (on ? t.primary : t.borderStrong));
    }
  }

  @override
  bool shouldRepaint(_BeadsPainter old) => old.lit != lit || old.t != t;
}
