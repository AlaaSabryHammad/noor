import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../library/favorites.dart';
import '../services/service_widgets.dart';
import '../settings/settings_controller.dart';
import 'khutab_data.dart';

IconData khutbaIcon(String category) => switch (category) {
      'faith' => Icons.auto_awesome_outlined,
      'worship' => Icons.mosque_outlined,
      'character' => Icons.handshake_outlined,
      'family' => Icons.family_restroom_outlined,
      'heart' => Icons.favorite_outline_rounded,
      'seasons' => Icons.nightlight_outlined,
      'prophetic' => Icons.history_edu_outlined,
      _ => Icons.record_voice_over_outlined,
    };

/// Friday sermons: this week's khutbah, categories and search.
class KhutabScreen extends ConsumerStatefulWidget {
  const KhutabScreen({super.key});
  @override
  ConsumerState<KhutabScreen> createState() => _KhutabScreenState();
}

class _KhutabScreenState extends ConsumerState<KhutabScreen> {
  String? _cat;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final ar = NoorFormat.isAr(context);
    final t = context.noor;
    final today = ref.watch(nowProvider.select((n) => DateTime(n.year, n.month, n.day)));
    final hijriOffset = ref.watch(settingsProvider.select((s) => s.hijriOffset));
    return ServiceScaffold(
      title: NoorFormat.tr(context, 'الخطب المنبرية', 'Sermons'),
      children: [
        ref.watch(khutabProvider).when(
          loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('$e'))),
          data: (lib) {
            final weekly = lib.weekly(today, hijriOffset: hijriOffset);
            final q = _q.toLowerCase();
            final list = lib.khutab.where((k) => (_cat == null || k.category == _cat) && (q.isEmpty || k.titleAr.contains(_q) || k.titleEn.toLowerCase().contains(q) || k.summaryAr.contains(_q) || k.summaryEn.toLowerCase().contains(q))).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              HeroSurface(
                onTap: () => context.push('/khutab/${weekly.id}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: [
                  Row(children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: NoorTokens.onHeroAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(NoorFormat.tr(context, 'خطبة هذا الأسبوع', 'This week’s khutbah'), style: const TextStyle(fontSize: 12.5, color: Color(0xD1FFFFFF)))),
                    Text(_minutes(context, weekly.minutes), style: const TextStyle(fontSize: 12, color: Color(0xBFFFFFFF))),
                  ]),
                  Text(weekly.title(ar), style: NoorText.display(context, size: 30, color: Colors.white)),
                  Text(weekly.summary(ar), style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xE6FFFFFF))),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF075E54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm))),
                        onPressed: () => context.push('/khutab/${weekly.id}'),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: Text(NoorFormat.tr(context, 'اقرأ الخطبة', 'Read')),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              NoorSearchField(hint: NoorFormat.tr(context, 'ابحث في الخطب', 'Search sermons'), onChanged: (v) => setState(() => _q = v.trim())),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(spacing: 8, children: [
                  for (final (id, label) in [(null, NoorFormat.tr(context, 'الكل', 'All')), for (final c in lib.categories) (c.id, c.name(ar))])
                    ChoiceChip(
                      label: Text(label),
                      selected: _cat == id,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _cat = id),
                      selectedColor: t.primary,
                      backgroundColor: t.surface,
                      labelStyle: TextStyle(color: _cat == id ? t.onPrimary : t.text, fontWeight: FontWeight.w600, fontSize: 13),
                      side: BorderSide(color: _cat == id ? t.primary : t.border),
                    ),
                ]),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                Padding(padding: const EdgeInsets.all(32), child: Text(NoorFormat.tr(context, 'لا نتائج', 'No results'), textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary))),
              for (final k in list) ...[
                NoorCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push('/khutab/${k.id}'),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
                    IconBadge(icon: khutbaIcon(k.category), gold: k.category == 'prophetic' || k.category == 'seasons', size: 46),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                        Text(k.title(ar), style: NoorText.display(context, size: 20)),
                        Text(k.summary(ar), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.55, color: t.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${lib.category(k.category)?.name(ar) ?? ''} · ${_minutes(context, k.minutes)}', style: TextStyle(fontSize: 12, color: t.goldText, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              Text(
                NoorFormat.tr(context, 'كُتبت هذه الخطب للتطبيق، ونصوص الآيات منقولة حرفيًا من المصحف، والأحاديث معزوّة إلى مصادرها.', 'These sermons were written for the app; Quranic text is quoted verbatim and every hadith cites its source.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]);
          },
        ),
      ],
    );
  }
}

String _minutes(BuildContext context, int m) => NoorFormat.tr(context, '${NoorFormat.digits(context, m)} دقائق', '$m min');

/// A sermon in reading layout: ayahs in the mushaf face, hadith with sources,
/// adjustable size, optional side-by-side translation.
class KhutbaScreen extends ConsumerStatefulWidget {
  const KhutbaScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<KhutbaScreen> createState() => _KhutbaScreenState();
}

class _KhutbaScreenState extends ConsumerState<KhutbaScreen> {
  bool _translation = false;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final fs = ref.watch(khutbaFontSizeProvider);
    final lib = ref.watch(khutabProvider);
    final k = lib.value?.byId(widget.id);
    return Scaffold(
      backgroundColor: t.reader,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(spacing: 6, children: [
              const NoorBackButton(),
              const Spacer(),
              NoorIconButton(icon: Icons.text_decrease_rounded, tooltip: NoorFormat.tr(context, 'تصغير الخط', 'Smaller text'), onPressed: () => ref.read(khutbaFontSizeProvider.notifier).set(fs - 2)),
              NoorIconButton(icon: Icons.text_increase_rounded, tooltip: NoorFormat.tr(context, 'تكبير الخط', 'Larger text'), onPressed: () => ref.read(khutbaFontSizeProvider.notifier).set(fs + 2)),
              NoorIconButton(
                icon: Icons.translate_rounded,
                tooltip: NoorFormat.tr(context, 'إظهار الترجمة', 'Show translation'),
                onPressed: () => setState(() => _translation = !_translation),
                child: Icon(Icons.translate_rounded, size: 21, color: _translation ? t.primary : t.text),
              ),
            ]),
          ),
          Expanded(
            child: switch (lib) {
              AsyncData() when k == null => Center(child: Text(NoorFormat.tr(context, 'لم يُعثر على هذه الخطبة.', 'Sermon not found.'))),
              AsyncData() => _body(context, k!, ar, fs),
              AsyncError(:final error) => Center(child: Text('$error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context, Khutba k, bool ar, double fs) {
    final t = context.noor;
    final cat = ref.watch(khutabProvider).value?.category(k.category);
    final saved = SavedItem(key: 'khutba:${k.id}', kind: 'khutba', title: k.titleAr, body: k.titleAr, translation: k.titleEn, source: NoorFormat.tr(context, 'خطبة · ${cat?.ar ?? ''}', 'Sermon · ${cat?.en ?? ''}'));
    return ColumnListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
      children: [
        Text(cat?.name(ar) ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: t.goldText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(k.title(ar), textAlign: TextAlign.center, style: NoorText.display(context, size: 30)),
        const SizedBox(height: 6),
        Text(k.summary(ar), textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary, height: 1.6)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.schedule_rounded, size: 16, color: t.textSecondary),
          const SizedBox(width: 4),
          Text(_minutes(context, k.minutes), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 12),
          IconButton(
            tooltip: NoorFormat.tr(context, 'نسخ الخطبة', 'Copy sermon'),
            icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: k.plainText(ar)));
              showNoorSnack(context, NoorFormat.tr(context, 'نُسخت الخطبة', 'Sermon copied'));
            },
          ),
          SaveButton(item: saved, tooltip: NoorFormat.tr(context, 'حفظ', 'Save')),
        ]),
        for (final p in k.parts) ...[
          const SizedBox(height: 18),
          // The rules shrink first; a long title wraps instead of overflowing.
          Row(spacing: 10, children: [
            Expanded(child: Divider(color: t.goldLine)),
            EightPointStar(size: 18, color: t.gold),
            Flexible(flex: 8, child: Text(p.title(ar), textAlign: TextAlign.center, style: NoorText.display(context, size: 19, color: t.goldText))),
            EightPointStar(size: 18, color: t.gold),
            Expanded(child: Divider(color: t.goldLine)),
          ]),
          const SizedBox(height: 14),
          for (final b in p.blocks) Padding(padding: const EdgeInsets.only(bottom: 14), child: KhutbaBlockView(block: b, ar: ar, fs: fs, translation: _translation)),
        ],
        const SizedBox(height: 10),
        Text(
          NoorFormat.tr(context, 'الآيات: نص المصحف (Tanzil) وترجمة صحيح إنترناشونال. يُرجى مراجعة الخطب مع أهل العلم قبل إلقائها.', 'Ayahs: Tanzil Uthmani text with Saheeh International. Please review sermons with a qualified scholar before delivering them.'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// One block of a sermon or spotlight: prose, an ayah in the mushaf face, or a hadith with its source.
class KhutbaBlockView extends StatelessWidget {
  const KhutbaBlockView({super.key, required this.block, required this.ar, required this.fs, required this.translation});
  final KhutbaBlock block;
  final bool ar, translation;
  final double fs;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    // Quran and hadith always appear in Arabic; prose follows the UI language.
    final arabicFirst = ar || block.kind != KhutbaBlockKind.paragraph;
    final second = arabicFirst ? (ar ? (translation ? block.en : null) : block.en) : (translation ? block.ar : null);
    final primary = arabicFirst ? block.ar : block.en;
    final ref = block.ref(ar);
    Widget secondary(String s, bool isAr) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            s,
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            style: isAr ? TextStyle(fontSize: fs * .85, height: 1.9, color: t.textSecondary) : TextStyle(fontFamily: NoorFonts.latinUi, fontSize: fs * .75, height: 1.6, color: t.textSecondary),
          ),
        );
    return switch (block.kind) {
      KhutbaBlockKind.ayah => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: t.primaryLine)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('﴿ $primary ﴾', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: NoorText.quran(context, size: fs + 4).copyWith(height: 2.1)),
            ?second == null ? null : secondary(second, false),
            const SizedBox(height: 8),
            Text(ref, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: t.primary, fontWeight: FontWeight.w600)),
          ]),
        ),
      KhutbaBlockKind.hadith => Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: BoxDecoration(color: t.goldSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: t.goldLine)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(primary, textDirection: TextDirection.rtl, style: NoorText.display(context, size: fs + 2).copyWith(height: 2, fontWeight: FontWeight.w400)),
            ?second == null ? null : secondary(second, false),
            const SizedBox(height: 8),
            Text(ref, textAlign: TextAlign.end, style: TextStyle(fontSize: 12, color: t.goldText, fontWeight: FontWeight.w600)),
          ]),
        ),
      KhutbaBlockKind.paragraph => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
            primary,
            textDirection: arabicFirst ? TextDirection.rtl : TextDirection.ltr,
            style: arabicFirst ? TextStyle(fontSize: fs, height: 2, color: t.text) : TextStyle(fontFamily: NoorFonts.latinUi, fontSize: fs * .9, height: 1.7, color: t.text),
          ),
          ?second == null ? null : secondary(second, !arabicFirst),
        ]),
    };
  }
}
