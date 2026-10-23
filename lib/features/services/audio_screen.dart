import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../quran/ayah_audio.dart';
import '../quran/quran_data.dart';
import 'service_widgets.dart';

/// Pick a reciter and a surah; the reader opens and starts the recitation.
class AudioScreen extends ConsumerStatefulWidget {
  const AudioScreen({super.key});
  @override
  ConsumerState<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final reciterId = ref.watch(reciterProvider);
    final reciter = reciters.firstWhere((r) => r.id == reciterId);
    final index = ref.watch(quranIndexProvider);
    final q = _q.toLowerCase();

    return ServiceScaffold(title: l.svcAudio, children: [
      NoorCard(
        padding: const EdgeInsets.all(14),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 16), children: [
              for (final r in reciters)
                ListTile(
                  title: Text(NoorFormat.isAr(ctx) ? r.ar : r.en),
                  trailing: r.id == reciterId ? Icon(Icons.check_rounded, color: ctx.noor.primary) : null,
                  onTap: () {
                    ref.read(reciterProvider.notifier).select(r.id);
                    Navigator.of(ctx).pop();
                  },
                ),
            ]),
          ),
        ),
        child: Row(spacing: 12, children: [
          const IconBadge(icon: Icons.headphones_outlined, solid: true, size: 44),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
              Text(NoorFormat.tr(context, 'القارئ', 'Reciter'), style: Theme.of(context).textTheme.bodySmall),
              Text(ar ? reciter.ar : reciter.en, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
            ]),
          ),
          Icon(Icons.expand_more_rounded, color: t.textSecondary),
        ]),
      ),
      const SizedBox(height: 12),
      NoorSearchField(hint: NoorFormat.tr(context, 'ابحث عن سورة', 'Search for a surah'), onChanged: (v) => setState(() => _q = v.trim())),
      const SizedBox(height: 12),
      index.when(
        loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final list = data.surahs.where((s) => q.isEmpty || s.nameAr.contains(_q) || s.nameEn.toLowerCase().contains(q) || '${s.number}' == q).toList();
          return NoorCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (var i = 0; i < list.length; i++) ...[
                if (i > 0) const Divider(indent: 16, endIndent: 16),
                ListTile(
                  minTileHeight: 60,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => context.push('/quran/reader/${list[i].number}?play=1'),
                  leading: EightPointStar(size: 38, color: t.gold, strokeWidth: .9, child: Text(NoorFormat.digits(context, list[i].number), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: t.primary))),
                  title: Text(ar ? 'سورة ${list[i].nameAr}' : list[i].nameEn, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(l.ayahCount(NoorFormat.digits(context, list[i].ayahCount)), style: Theme.of(context).textTheme.bodySmall),
                  trailing: Icon(Icons.play_circle_fill_rounded, color: t.primary, size: 30),
                ),
              ],
            ]),
          );
        },
      ),
      const SizedBox(height: 10),
      Text(NoorFormat.tr(context, 'تُبثّ التلاوة عبر الإنترنت من everyayah.com.', 'Recitation is streamed over the internet from everyayah.com.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
