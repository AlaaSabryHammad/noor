import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../books/books_screens.dart';
import '../services/service_widgets.dart';
import 'favorites.dart';
import 'share_image.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _kind = 'all';
  String _tab = 'saved';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final saved = ref.watch(favoritesProvider);
    final kinds = [
      ('all', NoorFormat.tr(context, 'الكل', 'All')),
      ('ayah', NoorFormat.tr(context, 'آيات', 'Ayahs')),
      ('hadith', NoorFormat.tr(context, 'أحاديث', 'Hadith')),
      ('dua', NoorFormat.tr(context, 'أدعية', 'Duas')),
      ('name', NoorFormat.tr(context, 'أسماء', 'Names')),
      ('khutba', NoorFormat.tr(context, 'خطب', 'Sermons')),
    ];
    final items = saved.where((e) => _kind == 'all' || e.kind == _kind).toList();
    final tabs = NoorSegmented<String>(
      values: const ['saved', 'books'],
      labels: [NoorFormat.tr(context, 'محفوظاتي', 'Saved'), l.svcBooks],
      selected: _tab,
      onChanged: (v) => setState(() => _tab = v),
    );
    if (_tab == 'books') return ServiceScaffold(title: l.svcLibrary, children: [tabs, const SizedBox(height: 14), const BooksView()]);

    return ServiceScaffold(title: l.svcLibrary, children: [
      tabs,
      const SizedBox(height: 14),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final (k, label) in kinds)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text('$label${k == 'all' ? ' (${NoorFormat.digits(context, saved.length)})' : ''}'),
                selected: _kind == k,
                showCheckmark: false,
                onSelected: (_) => setState(() => _kind = k),
                selectedColor: t.primary,
                labelStyle: TextStyle(color: _kind == k ? t.onPrimary : t.text, fontWeight: FontWeight.w600, fontSize: 13),
                backgroundColor: t.surface,
                side: BorderSide(color: _kind == k ? t.primary : t.border),
                shape: const StadiumBorder(),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      if (items.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Column(spacing: 12, children: [
            EightPointStar(size: 56, color: t.gold, strokeWidth: 1.4),
            Text(NoorFormat.tr(context, 'لا توجد عناصر محفوظة بعد', 'Nothing saved yet'), style: Theme.of(context).textTheme.titleMedium),
            Text(NoorFormat.tr(context, 'اضغط على أيقونة القلب في أي آية أو حديث أو دعاء أو اسم لحفظه هنا.', 'Tap the heart on any ayah, hadith, dua or name to keep it here.'),
                textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary, height: 1.7)),
          ]),
        ),
      for (final s in items) ...[
        NoorCard(
          onTap: s.kind == 'khutba' ? () => context.push('/khutab/${s.key.substring('khutba:'.length)}') : null,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 10, children: [
            Text(s.body, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: s.kind == 'ayah' ? NoorText.quran(context, size: 22).copyWith(height: 2) : NoorText.display(context, size: 20).copyWith(height: 2, fontWeight: FontWeight.w400)),
            if (s.translation.isNotEmpty) Text(s.translation, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13, height: 1.6, color: t.textSecondary)),
            const Divider(),
            Row(children: [
              Expanded(child: Text(s.source, style: TextStyle(fontSize: 11.5, color: t.goldText, height: 1.5, fontWeight: FontWeight.w600))),
              IconButton(
                tooltip: l.copy,
                icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: s.shareText));
                  showNoorSnack(context, l.copied);
                },
              ),
              if (s.kind != 'khutba') ShareImageButton(item: s),
              SaveButton(item: s, tooltip: NoorFormat.tr(context, 'إزالة من المحفوظات', 'Remove from saved')),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }
}
