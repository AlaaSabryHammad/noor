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
import 'service_widgets.dart';

/// Completed lesson indices for a course, persisted.
class CourseProgress extends Notifier<Set<int>> {
  CourseProgress(this.course);
  final String course;
  String get _k => 'academy.$course';

  @override
  Set<int> build() => (ref.watch(sharedPreferencesProvider).getStringList(_k) ?? const []).map(int.parse).toSet();

  void toggle(int i) {
    final next = {...state};
    next.contains(i) ? next.remove(i) : next.add(i);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_k, next.map((e) => '$e').toList());
  }

  void reset() {
    state = {};
    ref.read(sharedPreferencesProvider).remove(_k);
  }
}

final courseProgressProvider = NotifierProvider.family<CourseProgress, Set<int>, String>(CourseProgress.new);

IconData _icon(String name) => switch (name) {
      'water_drop' => Icons.water_drop_outlined,
      'mosque' => Icons.mosque_outlined,
      'account_balance' => Icons.account_balance_outlined,
      _ => Icons.auto_awesome_outlined,
    };

class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('academy'));
    return ServiceScaffold(title: l.svcAcademy, children: [
      Text(NoorFormat.tr(context, 'دروس خطوة بخطوة في أساسيات الدين. علّم الدرس عند إتمامه لتتابع تقدمك.', 'Step-by-step lessons on the basics. Tick each step to track your progress.'), style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 14),
      contentBody(data, (d) {
        final courses = (d['courses'] as List).cast<Map<String, dynamic>>();
        return Column(spacing: 10, children: [
          for (final c in courses) _CourseTile(course: c, ar: ar),
        ]);
      }),
    ]);
  }
}

class _CourseTile extends ConsumerWidget {
  const _CourseTile({required this.course, required this.ar});
  final Map<String, dynamic> course;
  final bool ar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = course['id'] as String;
    final total = (course['lessons'] as List).length;
    final done = ref.watch(courseProgressProvider(id)).length;
    return NoorCard(
      onTap: () => context.push('/academy/$id'),
      child: Row(spacing: 14, children: [
        IconBadge(icon: _icon(course['icon'] as String), size: 48, gold: id == 'prayer' || id == 'iman'),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
            Row(children: [
              Expanded(child: Text(pick(course, 'title', ar), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700))),
              Text('${NoorFormat.digits(context, done)} / ${NoorFormat.digits(context, total)}', style: Theme.of(context).textTheme.bodySmall),
            ]),
            NoorProgressBar(value: total == 0 ? 0 : done / total, color: context.noor.gold),
          ]),
        ),
      ]),
    );
  }
}

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final data = ref.watch(contentJsonProvider('academy'));
    final done = ref.watch(courseProgressProvider(courseId));
    final ctrl = ref.read(courseProgressProvider(courseId).notifier);
    final course = data.value == null ? null : (data.value!['courses'] as List).cast<Map<String, dynamic>>().where((c) => c['id'] == courseId).firstOrNull;

    return ServiceScaffold(
      title: course == null ? '' : pick(course, 'title', ar),
      children: [
        if (course == null) const Center(child: CircularProgressIndicator()),
        if (course != null) ...[
          () {
            final lessons = (course['lessons'] as List).cast<Map<String, dynamic>>();
            final complete = done.length >= lessons.length;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
              NoorProgressBar(value: lessons.isEmpty ? 0 : done.length / lessons.length, color: t.gold, height: 6),
              if (complete)
                HeroSurface(
                  radius: 22,
                  child: Column(spacing: 6, children: [
                    const EightPointStar(size: 40, color: NoorTokens.onHeroAccent, strokeWidth: 1.4, child: Icon(Icons.check_rounded, color: NoorTokens.onHeroAccent, size: 18)),
                    Text(NoorFormat.tr(context, 'أتممت الدرس', 'Lesson completed'), style: NoorText.display(context, size: 22, color: Colors.white)),
                    TextButton(onPressed: ctrl.reset, style: TextButton.styleFrom(foregroundColor: Colors.white), child: Text(AppLocalizations.of(context).restart)),
                  ]),
                ),
              for (var i = 0; i < lessons.length; i++)
                NoorCard(
                  borderColor: done.contains(i) ? t.primaryLine : null,
                  color: done.contains(i) ? t.primarySoft : null,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ctrl.toggle(i);
                  },
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: done.contains(i) ? t.primary : t.sunk, borderRadius: BorderRadius.circular(11)),
                      child: done.contains(i) ? Icon(Icons.check_rounded, size: 19, color: t.onPrimary) : Text(NoorFormat.digits(context, i + 1), style: TextStyle(fontWeight: FontWeight.w700, color: t.textSecondary)),
                    ),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                        Text(pick(lessons[i], 'title', ar), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(pick(lessons[i], 'body', ar), style: TextStyle(height: 1.75, color: t.textSecondary, fontSize: 13.5)),
                      ]),
                    ),
                  ]),
                ),
            ]);
          }(),
        ],
      ],
    );
  }
}
