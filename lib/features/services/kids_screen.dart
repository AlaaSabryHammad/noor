import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'service_widgets.dart';

const _kBest = 'kids.bestScore';

class KidsScreen extends ConsumerStatefulWidget {
  const KidsScreen({super.key});
  @override
  ConsumerState<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends ConsumerState<KidsScreen> {
  int _i = 0, _score = 0;
  int? _picked;
  bool _finished = false;

  void _restart() => setState(() {
        _i = 0;
        _score = 0;
        _picked = null;
        _finished = false;
      });

  void _answer(int choice, int correct, int total) {
    if (_picked != null) return;
    final ok = choice == correct;
    ok ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    setState(() {
      _picked = choice;
      if (ok) _score++;
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_i + 1 >= total) {
        final prefs = ref.read(sharedPreferencesProvider);
        if (_score > (prefs.getInt(_kBest) ?? 0)) prefs.setInt(_kBest, _score);
        setState(() => _finished = true);
      } else {
        setState(() {
          _i++;
          _picked = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('kids'));
    final best = ref.watch(sharedPreferencesProvider).getInt(_kBest) ?? 0;

    return ServiceScaffold(title: l.svcKids, children: [
      contentBody(data, (d) {
        final quiz = (d['quiz'] as List).cast<Map<String, dynamic>>();
        final manners = (d['manners'] as List).cast<Map<String, dynamic>>();
        final total = quiz.length;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
          HeroSurface(
            radius: 28,
            child: _finished
                ? Column(spacing: 8, children: [
                    const EightPointStar(size: 52, color: NoorTokens.onHeroAccent, strokeWidth: 1.4, child: Icon(Icons.star_rounded, color: NoorTokens.onHeroAccent, size: 22)),
                    Text(NoorFormat.tr(context, 'أحسنت!', 'Well done!'), style: NoorText.display(context, size: 30, color: Colors.white)),
                    Text(NoorFormat.tr(context, 'نتيجتك ${NoorFormat.digits(context, _score)} من ${NoorFormat.digits(context, total)}', 'You scored $_score out of $total'), style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 15)),
                    TextButton(onPressed: _restart, style: TextButton.styleFrom(foregroundColor: Colors.white), child: Text(l.restart)),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [
                    Row(children: [
                      Expanded(child: Text(NoorFormat.tr(context, 'سؤال ${NoorFormat.digits(context, _i + 1)} من ${NoorFormat.digits(context, total)}', 'Question ${_i + 1} of $total'), style: const TextStyle(fontSize: 12.5, color: NoorTokens.onHeroAccent, fontWeight: FontWeight.w600))),
                      Text(NoorFormat.tr(context, 'أفضل نتيجة: ${NoorFormat.digits(context, best)}', 'Best: $best'), style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF))),
                    ]),
                    Text(pick(quiz[_i], 'q', ar), style: NoorText.display(context, size: 24, color: Colors.white).copyWith(height: 1.5)),
                  ]),
          ),
          if (!_finished) ...[
            for (final (idx, o) in (quiz[_i]['options'] as List).cast<Map<String, dynamic>>().indexed)
              () {
                final correct = quiz[_i]['answer'] as int;
                final picked = _picked;
                final isRight = picked != null && idx == correct;
                final isWrong = picked == idx && idx != correct;
                return NoorCard(
                  color: isRight ? t.primarySoft : (isWrong ? const Color(0xFFFBEAE6) : null),
                  borderColor: isRight ? t.primary : (isWrong ? const Color(0xFFB23A1E) : null),
                  onTap: () => _answer(idx, correct, total),
                  child: Row(spacing: 12, children: [
                    Expanded(child: Text((ar ? o['ar'] : o['en']) as String, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isWrong ? const Color(0xFF8C2C14) : null))),
                    if (isRight) Icon(Icons.check_circle_rounded, color: t.primary),
                    if (isWrong) const Icon(Icons.cancel_rounded, color: Color(0xFFB23A1E)),
                  ]),
                );
              }(),
          ],
          const SizedBox(height: 6),
          SectionTitle(NoorFormat.tr(context, 'آداب جميلة', 'Good manners')),
          for (final m in manners)
            NoorCard(
              padding: const EdgeInsets.all(14),
              child: Row(spacing: 12, children: [
                const IconBadge(icon: Icons.favorite_outline_rounded, gold: true, size: 40),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                    Text(pick(m, 'title', ar), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(pick(m, 'body', ar), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ]),
            ),
        ]);
      }),
    ]);
  }
}
