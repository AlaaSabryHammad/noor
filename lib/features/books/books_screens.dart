import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../library/favorites.dart';
import '../library/share_image.dart';
import '../services/service_widgets.dart';
import 'books_data.dart';

String bookTitle(Book b, bool ar) => ar ? b.titleAr : b.titleEn;

/// 59.0 → 59, 1.5 → 1.5 (a few datasets number hadith with decimals).
String _num(num n) => n == n.roundToDouble() ? '${n.toInt()}' : '$n';

/// The catalogue of books; embedded in the Library tab and the Books screen.
class BooksView extends ConsumerWidget {
  const BooksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final catalog = ref.watch(booksCatalogProvider);
    return catalog.when(
      loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('$e'))),
      data: (books) => Column(spacing: 10, children: [
        for (final b in books)
          NoorCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push(b.sections.length == 1 ? '/books/${b.id}/${b.sections.first.n}' : '/books/${b.id}'),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 14, children: [
              IconBadge(icon: Icons.menu_book_rounded, gold: !b.bundled, size: 48),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: [
                  Text(bookTitle(b, ar), style: NoorText.display(context, size: 21)),
                  Text(ar ? b.authorAr : b.authorEn, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: t.goldText)),
                  Text(ar ? b.blurbAr : b.blurbEn, style: TextStyle(height: 1.6, color: t.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _Pill(icon: b.bundled ? Icons.offline_pin_outlined : Icons.cloud_download_outlined, text: b.bundled ? NoorFormat.tr(context, 'يعمل بدون إنترنت', 'Works offline') : NoorFormat.tr(context, 'يُحمَّل عند أول فتح', 'Downloads on first open')),
                    _Pill(icon: Icons.format_list_numbered_rounded, text: NoorFormat.tr(context, '${NoorFormat.digits(context, b.count)} حديثًا', '${b.count} hadith')),
                  ]),
                ]),
              ),
            ]),
          ),
        const SizedBox(height: 4),
        Text(
          NoorFormat.tr(context, 'نصوص الأحاديث من مشروع hadith-api المفتوح (ترخيص Unlicense). عناوين الأبواب بالإنجليزية كما نشرها المصدر.', 'Hadith text from the open hadith-api project (The Unlicense). Section titles are in English as published by the source.'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: t.sunk, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, spacing: 5, children: [Icon(icon, size: 14, color: t.textSecondary), Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: t.textSecondary, fontWeight: FontWeight.w500)))]),
    );
  }
}

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});
  @override
  Widget build(BuildContext context) => ServiceScaffold(title: AppLocalizations.of(context).svcBooks, children: const [BooksView()]);
}

/// Sections (chapters) of one book.
class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key, required this.bookId});
  final String bookId;
  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final book = ref.watch(bookProvider(widget.bookId));
    final b = book.value;
    final sections = (b?.sections ?? const <BookSection>[]).where((s) => _q.isEmpty || s.title.toLowerCase().contains(_q.toLowerCase()) || '${s.n}' == _q).toList();
    return ServiceScaffold(
      title: b == null ? '' : bookTitle(b, ar),
      children: [
        if (b == null && book.isLoading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        if (b == null && !book.isLoading) Center(child: Text(NoorFormat.tr(context, 'الكتاب غير موجود', 'Book not found'))),
        if (b != null) ...[
          NoorSearchField(hint: NoorFormat.tr(context, 'ابحث في الأبواب', 'Search sections'), onChanged: (v) => setState(() => _q = v.trim())),
          const SizedBox(height: 12),
          NoorCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                ListTile(
                  minTileHeight: 58,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => context.push('/books/${b.id}/${sections[i].n}'),
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(12)),
                    child: Text(NoorFormat.digits(context, sections[i].n), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: t.primary)),
                  ),
                  title: Text(sections[i].title, textDirection: TextDirection.ltr, textAlign: ar ? TextAlign.right : TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                  subtitle: sections[i].first == null ? null : Text(NoorFormat.tr(context, 'الأحاديث ${NoorFormat.digits(context, _num(sections[i].first!))}–${NoorFormat.digits(context, _num(sections[i].last!))}', 'Hadith ${_num(sections[i].first!)}–${_num(sections[i].last!)}'), style: Theme.of(context).textTheme.bodySmall),
                  trailing: Icon(Icons.chevron_right_rounded, color: t.textSecondary),
                ),
              ],
            ]),
          ),
          if (sections.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(NoorFormat.tr(context, 'لا توجد نتائج', 'No results'), style: TextStyle(color: t.textSecondary)))),
        ],
      ],
    );
  }
}

/// The hadith of one section, with a translation toggle, copy and save.
class SectionScreen extends ConsumerStatefulWidget {
  const SectionScreen({super.key, required this.bookId, required this.section});
  final String bookId;
  final int section;
  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen> {
  bool _showEnglish = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final book = ref.watch(bookProvider(widget.bookId)).value;
    final hadith = ref.watch(bookSectionProvider((widget.bookId, widget.section)));
    final section = book?.sections.where((s) => s.n == widget.section).firstOrNull;
    final single = (book?.sections.length ?? 0) == 1;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          ContentColumn(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(children: [
              const NoorBackButton(),
              Expanded(
                child: Column(children: [
                  Text(book == null ? '' : bookTitle(book, ar), textAlign: TextAlign.center, style: NoorText.display(context, size: 20)),
                  if (!single && section != null) Text(section.title, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              NoorIconButton(
                icon: Icons.translate_rounded,
                tooltip: NoorFormat.tr(context, 'الترجمة الإنجليزية', 'English translation'),
                filled: _showEnglish,
                onPressed: () => setState(() => _showEnglish = !_showEnglish),
              ),
            ]),
          ),
          Expanded(
            child: hadith.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(mainAxisSize: MainAxisSize.min, spacing: 14, children: [
                    Icon(Icons.cloud_off_rounded, size: 44, color: t.textSecondary),
                    Text(NoorFormat.tr(context, 'تعذّر تحميل هذا الباب. يلزم اتصال بالإنترنت أول مرة فقط.', 'Couldn’t load this section. An internet connection is needed the first time only.'), textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary, height: 1.7)),
                    NoorPrimaryButton(label: NoorFormat.tr(context, 'إعادة المحاولة', 'Try again'), onPressed: () => ref.invalidate(bookSectionProvider((widget.bookId, widget.section)))),
                  ]),
                ),
              ),
              data: (list) => ColumnListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final h = list[i];
                  final src = '${book == null ? '' : bookTitle(book, ar)} · ${NoorFormat.tr(context, 'حديث', 'Hadith')} ${NoorFormat.digits(context, h.n)}';
                  final item = SavedItem(key: 'book:${widget.bookId}:${h.n}', kind: 'hadith', title: src, body: h.ar, translation: h.en, source: src);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: NoorCard(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
                        Row(children: [
                          Container(
                            constraints: const BoxConstraints(minWidth: 34),
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(10)),
                            child: Text(NoorFormat.digits(context, h.n), style: TextStyle(color: t.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                          ),
                          if (h.grade.isNotEmpty) ...[const SizedBox(width: 8), Flexible(child: Text(h.grade, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: t.goldText)))],
                          const Spacer(),
                          IconButton(
                            tooltip: l.copy,
                            icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.shareText));
                              showNoorSnack(context, l.copied);
                            },
                          ),
                          ShareImageButton(item: item),
                          SaveButton(item: item, tooltip: l.save),
                        ]),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: Text(h.ar, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: NoorText.display(context, size: 20).copyWith(height: 2, fontWeight: FontWeight.w400)),
                        ),
                        if (_showEnglish && h.en.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Text(h.en, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13, height: 1.65, color: t.textSecondary)),
                          ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
