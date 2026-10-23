import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import '../library/favorites.dart';
import 'ayah_audio.dart';
import 'quran_data.dart';

enum _Mode { mushaf, translation }

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.surah, this.autoplay = false});
  final int surah;

  /// Start the recitation as soon as the text has loaded (from the Audio screen).
  final bool autoplay;
  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  _Mode _mode = _Mode.mushaf;

  // Recitation streams one MP3 per ayah (everyayah.com); the highlight follows
  // the player's current track.
  AyahAudio? _audio;
  final _subs = <StreamSubscription<Object?>>[];
  bool _playing = false, _started = false, _autoplayed = false;
  late int _current;
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void initState() {
    super.initState();
    // Resume where the reader left off in this surah.
    final saved = ref.read(readingProgressProvider);
    _current = saved.surah == widget.surah ? saved.ayah : 1;
  }

  void _save(int ayah) {
    final page = ref.read(quranIndexProvider).value?.estimatePage(widget.surah, ayah);
    ref.read(readingProgressProvider.notifier).markRead(widget.surah, ayah, page: page);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _audio?.dispose();
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _stopped() {
    if (mounted) setState(() => _playing = _started = false);
  }

  AyahAudio _player() {
    final existing = _audio;
    if (existing != null) return existing;
    final a = _audio = ref.read(ayahAudioFactoryProvider)();
    _subs.addAll([
      a.ayah.listen((n) {
        if (!mounted) return;
        setState(() => _current = n);
        _save(n);
      }),
      a.playing.listen((p) {
        if (mounted) setState(() => _playing = p);
      }),
      a.completed.listen((_) => _stopped()),
      a.errors.listen((_) {
        _stopped();
        if (mounted) showNoorSnack(context, NoorFormat.tr(context, 'تعذّر تشغيل التلاوة. تحقق من اتصالك بالإنترنت.', 'Couldn’t play the recitation. Check your internet connection.'));
      }),
    ]);
    return a;
  }

  Future<void> _togglePlay(int total) async {
    HapticFeedback.lightImpact();
    final a = _player();
    if (_playing) return a.pause();
    if (_started) return a.resume();
    _started = true;
    final from = _current >= total ? 1 : _current;
    setState(() => _current = from);
    await a.start(reciterId: ref.read(reciterProvider), surah: widget.surah, fromAyah: from, total: total);
  }

  /// A different reciter needs a fresh playlist, so playback stops.
  Future<void> _pickReciter() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: 16), children: [
          for (final r in reciters)
            ListTile(
              title: Text(NoorFormat.isAr(ctx) ? r.ar : r.en),
              trailing: ref.read(reciterProvider) == r.id ? Icon(Icons.check_rounded, color: ctx.noor.primary) : null,
              onTap: () => Navigator.of(ctx).pop(r.id),
            ),
        ]),
      ),
    );
    if (id == null || id == ref.read(reciterProvider)) return;
    ref.read(reciterProvider.notifier).select(id);
    await _audio?.pause();
    _audio?.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _audio = null;
    _stopped();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ayahs = ref.watch(ayahsProvider(widget.surah));
    final surah = ref.watch(quranIndexProvider).value?.surahs.where((s) => s.number == widget.surah).firstOrNull;
    final fs = ref.watch(settingsProvider.select((s) => s.quranFontSize));
    if (widget.autoplay && !_autoplayed && ayahs.value != null) {
      _autoplayed = true;
      final total = ayahs.value!.length;
      // Opening a surah from the Audio screen always starts from its first ayah.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _current = 1);
        _togglePlay(total);
      });
    }

    return Scaffold(
      backgroundColor: t.reader,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              const NoorBackButton(),
              Expanded(
                child: Column(children: [
                  Text(surah == null ? '' : (NoorFormat.isAr(context) ? 'سورة ${surah.nameAr}' : surah.nameEn), style: NoorText.display(context, size: 20)),
                  if (surah != null)
                    Text('${surah.revelation == Revelation.meccan ? l.meccan : l.medinan} · ${l.ayahCount(NoorFormat.digits(context, surah.ayahCount))}', style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
              NoorIconButton(icon: Icons.text_decrease_rounded, tooltip: 'A-', onPressed: () => ref.read(settingsProvider.notifier).setQuranFontSize(fs - 2)),
              const SizedBox(width: 6),
              NoorIconButton(icon: Icons.text_increase_rounded, tooltip: 'A+', onPressed: () => ref.read(settingsProvider.notifier).setQuranFontSize(fs + 2)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NoorSegmented<_Mode>(values: _Mode.values, labels: [l.mushafMode, l.translationMode], selected: _mode, onChanged: (m) => setState(() => _mode = m)),
          ),
          Expanded(
            child: ayahs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) => list == null
                  ? _NotAvailable(message: l.notInSample)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                      children: [
                        _SurahHeader(nameAr: surah?.nameAr ?? ''),
                        const SizedBox(height: 14),
                        // Tanzil keeps the basmala inside ayah 1; it is shown here instead.
                        // Al-Fatihah counts it as ayah 1 and At-Tawbah has none.
                        if (widget.surah != 1 && widget.surah != 9) ...[
                          Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: NoorText.quran(context, size: fs).copyWith(height: 1.8)),
                          const SizedBox(height: 10),
                        ],
                        if (_mode == _Mode.mushaf) _mushaf(context, list, fs) else ..._translation(context, list, fs),
                      ],
                    ),
            ),
          ),
        ]),
      ),
      bottomSheet: ayahs.value == null
          ? null
          : _PlayerBar(
              playing: _playing,
              current: _current,
              total: ayahs.value!.length,
              reciterName: () {
                final r = reciters.firstWhere((r) => r.id == ref.watch(reciterProvider));
                return NoorFormat.isAr(context) ? r.ar : r.en;
              }(),
              onToggle: () => _togglePlay(ayahs.value!.length),
              onReciter: _pickReciter,
            ),
    );
  }

  Widget _mushaf(BuildContext context, List<Ayah> list, double fs) {
    final t = context.noor;
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final spans = <InlineSpan>[];
    for (final a in list) {
      final rec = TapGestureRecognizer()
        ..onTap = () {
          setState(() => _current = a.number);
          _save(a.number);
          _openTafsir(context, a);
        };
      _recognizers.add(rec);
      final active = _playing && a.number == _current;
      spans.add(TextSpan(
        text: a.ar,
        recognizer: rec,
        style: TextStyle(backgroundColor: active ? (Theme.of(context).brightness == Brightness.dark ? const Color(0x2EE0C486) : const Color(0xFFF3E6C6)) : null),
        semanticsLabel: a.ar,
      ));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: EightPointStar(
            size: fs * 1.15,
            color: t.gold,
            child: Text(NoorFormat.digits(context, a.number).replaceAllMapped(RegExp(r'\d'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]),
                style: TextStyle(fontFamily: NoorFonts.display, fontSize: fs * .42, fontWeight: FontWeight.w700, color: t.goldText)),
          ),
        ),
      ));
      spans.add(const TextSpan(text: ' '));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: t.goldLine)),
      child: Text.rich(TextSpan(children: spans), textDirection: TextDirection.rtl, textAlign: TextAlign.justify, style: NoorText.quran(context, size: fs).copyWith(height: 2.3)),
    );
  }

  List<Widget> _translation(BuildContext context, List<Ayah> list, double fs) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return [
      for (final a in list) ...[
        NoorCard(
          borderColor: _playing && a.number == _current ? t.gold : null,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: [
            Row(children: [
              Container(
                constraints: const BoxConstraints(minWidth: 30),
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(10)),
                child: Text(NoorFormat.digits(context, a.number), style: TextStyle(color: t.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ),
              const Spacer(),
              IconButton(tooltip: l.tafsir, icon: Icon(Icons.menu_book_outlined, size: 19, color: t.textSecondary), onPressed: () => _openTafsir(context, a)),
              IconButton(
                tooltip: l.copy,
                icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary),
                onPressed: () => _copy(context, a),
              ),
              SaveButton(item: _savedItem(a), tooltip: l.save),
            ]),
            Text(a.ar, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: NoorText.quran(context, size: fs).copyWith(height: 2.1)),
            Text(a.en, textDirection: TextDirection.ltr, textAlign: TextAlign.left, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13.5, height: 1.6, color: t.textSecondary)),
          ]),
        ),
        const SizedBox(height: 10),
      ],
      Text(l.translationSource, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ];
  }

  SavedItem _savedItem(Ayah a) {
    final surah = ref.read(quranIndexProvider).value?.surahs.where((s) => s.number == widget.surah).firstOrNull;
    final source = '﴿${surah?.nameAr ?? ''}: ${NoorFormat.digits(context, a.number)}﴾';
    return SavedItem(key: 'ayah:${widget.surah}:${a.number}', kind: 'ayah', title: source, body: a.ar, translation: a.en, source: source);
  }

  void _copy(BuildContext context, Ayah a) {
    final surah = ref.read(quranIndexProvider).value?.surahs.where((s) => s.number == widget.surah).firstOrNull;
    Clipboard.setData(ClipboardData(text: '${a.ar}\n﴿${surah?.nameAr ?? ''}: ${a.number}﴾'));
    showNoorSnack(context, AppLocalizations.of(context).copied);
  }

  void _openTafsir(BuildContext context, Ayah a) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final t = ctx.noor;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: [
              Text('${l.tafsir} · ${NoorFormat.digits(ctx, a.number)}', style: Theme.of(ctx).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(18)),
                child: Text(a.ar, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: NoorText.quran(ctx, size: 24).copyWith(height: 2.1)),
              ),
              Text(a.en, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13, color: t.textSecondary, height: 1.6)),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: t.goldLine)),
                child: Text(l.tafsirPlaceholder, style: TextStyle(color: t.textSecondary, height: 1.8)),
              ),
              Row(spacing: 8, children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _copy(ctx, a), icon: const Icon(Icons.copy_rounded, size: 18), label: Text(l.copy))),
                SaveButton(item: _savedItem(a), tooltip: l.save, size: 24),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.nameAr});
  final String nameAr;
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Container(
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.gold)),
      child: Container(
        margin: const EdgeInsets.all(6),
        alignment: Alignment.center,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: t.gold.withValues(alpha: .5), width: .6)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 16, children: [
          EightPointStar(size: 18, color: t.gold),
          Text('سُورَةُ $nameAr', textDirection: TextDirection.rtl, style: NoorText.quran(context, size: 22).copyWith(height: 1.4)),
          EightPointStar(size: 18, color: t.gold),
        ]),
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({required this.playing, required this.current, required this.total, required this.reciterName, required this.onToggle, required this.onReciter});
  final bool playing;
  final int current, total;
  final String reciterName;
  final VoidCallback onToggle, onReciter;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: t.border), boxShadow: t.cardShadow),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, spacing: 10, children: [
          NoorProgressBar(value: current / total, height: 3),
          Row(spacing: 10, children: [
            const IconBadge(icon: Icons.headphones_outlined),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                InkWell(
                  onTap: onReciter,
                  borderRadius: BorderRadius.circular(8),
                  child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
                    Flexible(child: Text(reciterName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                    Icon(Icons.expand_more_rounded, size: 18, color: t.textSecondary),
                  ]),
                ),
                Text(l.ayahOf(NoorFormat.digits(context, current), NoorFormat.digits(context, total)), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            IconButton.filled(
              tooltip: playing ? l.pause : l.play,
              style: IconButton.styleFrom(backgroundColor: t.primary, foregroundColor: t.onPrimary, fixedSize: const Size(48, 48)),
              onPressed: onToggle,
              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
          EightPointStar(size: 56, color: t.gold, strokeWidth: 1.4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary, height: 1.7)),
        ]),
      ),
    );
  }
}
