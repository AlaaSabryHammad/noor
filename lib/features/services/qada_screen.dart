import 'dart:convert';

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
import '../prayer/domain/prayer_models.dart';
import '../prayer/prayer_providers.dart' show prayerName;
import 'service_widgets.dart';

const qadaPrayers = [PrayerKind.fajr, PrayerKind.dhuhr, PrayerKind.asr, PrayerKind.maghrib, PrayerKind.isha];

/// Missed prayers and fasts still owed, and how many have been made up.
@immutable
class QadaState {
  const QadaState({this.prayers = const {}, this.fasts = 0, this.prayersDone = 0, this.fastsDone = 0});
  final Map<PrayerKind, int> prayers;
  final int fasts, prayersDone, fastsDone;

  int owed(PrayerKind k) => prayers[k] ?? 0;
  int get prayersLeft => qadaPrayers.fold(0, (s, k) => s + owed(k));

  QadaState copyWith({Map<PrayerKind, int>? prayers, int? fasts, int? prayersDone, int? fastsDone}) =>
      QadaState(prayers: prayers ?? this.prayers, fasts: fasts ?? this.fasts, prayersDone: prayersDone ?? this.prayersDone, fastsDone: fastsDone ?? this.fastsDone);

  Map<String, Object> toJson() => {'p': {for (final k in qadaPrayers) k.name: owed(k)}, 'f': fasts, 'pd': prayersDone, 'fd': fastsDone};
  factory QadaState.fromJson(Map<String, dynamic> j) {
    final p = j['p'] is Map ? (j['p'] as Map).cast<String, dynamic>() : const <String, dynamic>{};
    return QadaState(
      prayers: {for (final k in qadaPrayers) k: ((p[k.name] as num?)?.toInt() ?? 0).clamp(0, 1 << 20)},
      fasts: ((j['f'] as num?)?.toInt() ?? 0).clamp(0, 1 << 20),
      prayersDone: (j['pd'] as num?)?.toInt() ?? 0,
      fastsDone: (j['fd'] as num?)?.toInt() ?? 0,
    );
  }
}

class QadaController extends Notifier<QadaState> {
  static const _k = 'qada.v1';

  @override
  QadaState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_k);
    if (raw == null) return const QadaState();
    try {
      return QadaState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const QadaState();
    }
  }

  void _set(QadaState s) {
    state = s;
    ref.read(sharedPreferencesProvider).setString(_k, jsonEncode(s.toJson()));
  }

  /// Changes what is owed for one prayer without counting it as made up.
  void adjust(PrayerKind k, int delta) => _set(state.copyWith(prayers: {...state.prayers, k: (state.owed(k) + delta).clamp(0, 1 << 20)}));

  /// One prayer made up: owed goes down, the made-up tally goes up.
  void madeUp(PrayerKind k) {
    if (state.owed(k) == 0) return;
    _set(state.copyWith(prayers: {...state.prayers, k: state.owed(k) - 1}, prayersDone: state.prayersDone + 1));
  }

  /// Adds [days] full days of missed prayers (all five each day).
  void addDays(int days) {
    if (days <= 0) return;
    _set(state.copyWith(prayers: {for (final k in qadaPrayers) k: state.owed(k) + days}));
  }

  void adjustFasts(int delta) => _set(state.copyWith(fasts: (state.fasts + delta).clamp(0, 1 << 20)));

  void fastMadeUp() {
    if (state.fasts == 0) return;
    _set(state.copyWith(fasts: state.fasts - 1, fastsDone: state.fastsDone + 1));
  }

  void reset() => _set(const QadaState());
}

final qadaProvider = NotifierProvider<QadaController, QadaState>(QadaController.new);

/// Tracker for missed obligatory prayers and fasts to make up.
class QadaScreen extends ConsumerWidget {
  const QadaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final s = ref.watch(qadaProvider);
    final c = ref.read(qadaProvider.notifier);
    String n(int v) => NoorFormat.digits(context, v);
    return ServiceScaffold(
      title: l.svcQada,
      trailing: NoorIconButton(
        icon: Icons.restart_alt_rounded,
        tooltip: NoorFormat.tr(context, 'تصفير', 'Reset'),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(NoorFormat.tr(ctx, 'تصفير المتتبّع؟', 'Reset the tracker?')),
              content: Text(NoorFormat.tr(ctx, 'ستُحذف كل الأعداد المسجّلة.', 'All recorded counts will be cleared.')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(NoorFormat.tr(ctx, 'تصفير', 'Reset'))),
              ],
            ),
          );
          if (ok ?? false) c.reset();
        },
      ),
      children: [
        HeroSurface(
          child: Row(children: [
            Expanded(child: _Total(label: NoorFormat.tr(context, 'صلوات متبقية', 'Prayers left'), value: n(s.prayersLeft), sub: NoorFormat.tr(context, 'قُضي ${n(s.prayersDone)}', '${s.prayersDone} made up'))),
            Container(width: 1, height: 56, color: const Color(0x33FFFFFF)),
            Expanded(child: _Total(label: NoorFormat.tr(context, 'أيام صيام', 'Fasts left'), value: n(s.fasts), sub: NoorFormat.tr(context, 'قُضي ${n(s.fastsDone)}', '${s.fastsDone} made up'))),
          ]),
        ),
        const SizedBox(height: 18),
        SectionTitle(
          NoorFormat.tr(context, 'الصلوات الفائتة', 'Missed prayers'),
          trailing: TextButton.icon(onPressed: () => _addDays(context, ref), icon: const Icon(Icons.add_rounded, size: 18), label: Text(NoorFormat.tr(context, 'أيام كاملة', 'Whole days'))),
        ),
        const SizedBox(height: 8),
        NoorCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            for (final (i, k) in qadaPrayers.indexed) ...[
              if (i > 0) const Divider(indent: 16, endIndent: 16),
              _CounterRow(
                label: prayerName(l, k),
                value: s.owed(k),
                onMinus: () => c.adjust(k, -1),
                onPlus: () => c.adjust(k, 1),
                onDone: () {
                  HapticFeedback.lightImpact();
                  c.madeUp(k);
                },
                doneLabel: NoorFormat.tr(context, 'قضيتُها', 'Made up'),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 18),
        SectionTitle(NoorFormat.tr(context, 'أيام الصيام الفائتة', 'Missed fasts')),
        const SizedBox(height: 8),
        NoorCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _CounterRow(
            label: NoorFormat.tr(context, 'من رمضان', 'From Ramadan'),
            value: s.fasts,
            onMinus: () => c.adjustFasts(-1),
            onPlus: () => c.adjustFasts(1),
            onDone: () {
              HapticFeedback.lightImpact();
              c.fastMadeUp();
            },
            doneLabel: NoorFormat.tr(context, 'صمتُ يومًا', 'Fasted one'),
          ),
        ),
        const SizedBox(height: 18),
        NoorCard(
          color: t.goldSoft,
          borderColor: t.goldLine,
          padding: const EdgeInsets.all(14),
          onTap: () => context.push('/ask'),
          child: Row(spacing: 12, children: [
            Icon(Icons.info_outline_rounded, color: t.goldText),
            Expanded(
              child: Text(
                NoorFormat.tr(context, 'اجعل لك وِردًا ثابتًا، كصلاة فائتة مع كل فريضة. وفي أحكام القضاء تفصيل بين المذاهب؛ اطّلع عليه في «اسأل وتعلّم» أو اسأل أهل العلم.', 'Keep a steady routine, such as one missed prayer with every obligatory one. The schools differ on details of making up; see “Ask & learn” or ask a scholar.'),
                style: const TextStyle(fontSize: 13, height: 1.6),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(NoorFormat.tr(context, 'تُحفظ الأعداد على جهازك فقط.', 'Counts are stored on your device only.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _addDays(BuildContext context, WidgetRef ref) async {
    final field = TextEditingController();
    var unit = 1; // days per unit: 1, 30, 354
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(NoorFormat.tr(ctx, 'إضافة أيام فائتة', 'Add missed days')),
          content: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
            Text(NoorFormat.tr(ctx, 'تُضاف الصلوات الخمس عن كل يوم.', 'All five prayers are added for each day.'), style: Theme.of(ctx).textTheme.bodySmall),
            TextField(controller: field, keyboardType: TextInputType.number, autofocus: true, decoration: InputDecoration(hintText: NoorFormat.tr(ctx, 'العدد', 'Number'))),
            NoorSegmented<int>(
              values: const [1, 30, 354],
              labels: [NoorFormat.tr(ctx, 'أيام', 'Days'), NoorFormat.tr(ctx, 'أشهر', 'Months'), NoorFormat.tr(ctx, 'سنوات', 'Years')],
              selected: unit,
              dense: true,
              onChanged: (v) => setState(() => unit = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, (int.tryParse(NoorFormat.latinDigits(field.text.trim())) ?? 0) * unit), child: Text(NoorFormat.tr(ctx, 'إضافة', 'Add'))),
          ],
        ),
      ),
    );
    field.dispose();
    if (days != null && days > 0) ref.read(qadaProvider.notifier).addDays(days);
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.sub});
  final String label, value, sub;
  @override
  Widget build(BuildContext context) => Column(spacing: 2, children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xD1FFFFFF))),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: NoorText.display(context, size: 36, color: Colors.white))),
        Text(sub, style: const TextStyle(fontSize: 12, color: NoorTokens.onHeroAccent)),
      ]);
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({required this.label, required this.value, required this.onMinus, required this.onPlus, required this.onDone, required this.doneLabel});
  final String label, doneLabel;
  final int value;
  final VoidCallback onMinus, onPlus, onDone;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text(NoorFormat.digits(context, value), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: value == 0 ? t.textSecondary : t.primary)),
          ]),
        ),
        IconButton(tooltip: NoorFormat.tr(context, 'إنقاص', 'Decrease'), onPressed: value == 0 ? null : onMinus, icon: const Icon(Icons.remove_rounded)),
        IconButton(tooltip: NoorFormat.tr(context, 'زيادة', 'Increase'), onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
        Flexible(child: NoorPrimaryButton(label: doneLabel, soft: true, onPressed: value == 0 ? null : onDone)),
      ]),
    );
  }
}
