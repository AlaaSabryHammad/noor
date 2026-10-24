import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';

class _Service {
  const _Service(this.icon, this.label, this.route, {this.gold = false});
  final IconData icon;
  final String label;
  final String route;
  final bool gold;
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = <(String, List<_Service>)>[
      (l.groupWorship, [
        _Service(Icons.blur_circular_rounded, l.svcTasbeeh, '/tasbeeh', gold: true),
        _Service(Icons.volunteer_activism_outlined, l.svcDuas, '/duas'),
        _Service(Icons.auto_stories_rounded, Localizations.localeOf(context).languageCode == 'ar' ? 'حصن المسلم' : 'Hisn al-Muslim', '/hisn', gold: true),
        _Service(Icons.auto_awesome_outlined, l.svcNames, '/names', gold: true),
        _Service(Icons.checklist_rounded, l.svcPlanner, '/planner'),
        _Service(Icons.event_repeat_rounded, l.svcQada, '/qada'),
        _Service(Icons.savings_outlined, l.svcZakat, '/zakat', gold: true),
        _Service(Icons.headphones_outlined, l.svcAudio, '/audio'),
        _Service(Icons.radio_outlined, l.svcRadio, '/audio?tab=radio', gold: true),
      ]),
      (l.groupKnowledge, [
        _Service(Icons.wb_twilight_rounded, l.svcSpotlights, '/spotlights'),
        _Service(Icons.record_voice_over_outlined, l.svcKhutab, '/khutab', gold: true),
        _Service(Icons.school_rounded, l.svcLessons, '/audio?tab=lessons'),
        _Service(Icons.receipt_long_outlined, l.svcHadith, '/hadith'),
        _Service(Icons.timeline_rounded, l.svcSeerah, '/seerah', gold: true),
        _Service(Icons.school_outlined, l.svcAcademy, '/academy'),
        _Service(Icons.auto_stories_outlined, l.svcStories, '/stories', gold: true),
        _Service(Icons.library_books_outlined, l.svcBooks, '/books'),
        _Service(Icons.bookmarks_outlined, l.svcLibrary, '/library', gold: true),
        _Service(Icons.forum_outlined, l.svcAsk, '/ask'),
      ]),
      (l.groupSeasons, [
        _Service(Icons.calendar_month_outlined, l.svcCalendar, '/calendar'),
        _Service(Icons.nightlight_outlined, l.svcRamadan, '/ramadan', gold: true),
        _Service(Icons.mosque_outlined, l.svcHajj, '/hajj'),
      ]),
      (l.groupCommunity, [
        _Service(Icons.child_care_outlined, l.svcKids, '/kids', gold: true),
        _Service(Icons.place_outlined, l.svcMosques, '/mosques'),
        _Service(Icons.explore_outlined, l.svcQibla, '/qibla', gold: true),
      ]),
    ];

    return SafeArea(
      bottom: false,
      child: ColumnListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, NoorLayout.navClearance(context)),
        children: [
          ScreenTitle(l.exploreTitle),
          const SizedBox(height: 14),
          NoorSearchField(hint: l.searchAll, onChanged: (v) => setState(() => _q = v.trim())),
          // Beyond the service names: one tap searches the content itself.
          const SizedBox(height: 10),
          NoorCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: () => context.push('/search?q=${Uri.encodeQueryComponent(_q)}'),
            child: Row(spacing: 10, children: [
              Icon(Icons.manage_search_rounded, color: context.noor.primary),
              Expanded(
                child: Text(
                  _q.isEmpty ? l.svcSearch : NoorFormat.tr(context, 'ابحث عن «$_q» في القرآن وكل المحتوى', 'Search “$_q” in the Quran and all content'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.noor.primary),
                ),
              ),
              Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded, color: context.noor.textSecondary),
            ]),
          ),
          for (final (title, items) in groups)
            if (items.any((s) => s.label.toLowerCase().contains(_q.toLowerCase()))) ...[
              const SizedBox(height: 20),
              SectionTitle(title),
              const SizedBox(height: 10),
              GridView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                // Cell height follows the system text size so labels never overflow.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: NoorLayout.isWide(context) ? 4 : 3, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 112 + 56 * (MediaQuery.textScalerOf(context).scale(13) / 13 - 1).clamp(0, 1.5)),
                children: [
                  for (final s in items.where((s) => s.label.toLowerCase().contains(_q.toLowerCase())))
                    NoorCard(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      onTap: () => context.push(s.route),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 8, children: [
                        IconBadge(icon: s.icon, gold: s.gold),
                        Text(s.label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                      ]),
                    ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

/// Placeholder for services whose static designs exist on the canvas.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.service});
  final String service;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: NoorBackButton()),
            const Spacer(),
            EightPointStar(size: 72, color: t.gold, strokeWidth: 1.4),
            const SizedBox(height: 16),
            Text(l.comingSoonTitle, style: NoorText.display(context, size: 26)),
            const SizedBox(height: 8),
            Text(l.comingSoonBody, textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary, height: 1.7)),
            const Spacer(flex: 2),
          ]),
        ),
      ),
    );
  }
}
