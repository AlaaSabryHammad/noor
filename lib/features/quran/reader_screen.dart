import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../library/favorites.dart';
import '../settings/settings_controller.dart';
import 'ayah_audio.dart';
import 'quran_data.dart';

enum _Mode { mushaf, translation }

/// Ayahs grouped into one lazily built paragraph in mushaf mode.
const _chunkSize = 6;

const _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.surah, this.ayah, this.autoplay = false});
  final int surah;

  /// Ayah to open at; defaults to the saved position when it is in this surah.
  final int? ayah;

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
  late int _current; // ayah being recited / last tapped
  late int _topAyah; // first ayah on screen, drives the bookmark and mode switches

  final _scroll = ItemScrollController();
  final _positions = ItemPositionsListener.create();
  Timer? _saveTimer;
  int _lastAutoItem = -1;

  bool get _hasBasmala => widget.surah != 1 && widget.surah != 9; // Tanzil keeps it inside ayah 1 elsewhere
  int get _headerCount => _hasBasmala ? 2 : 1;

  @override
  void initState() {
    super.initState();
    // Open at the requested ayah, else resume where the reader left off in this surah.
    final saved = ref.read(readingProgressProvider);
    _current = _topAyah = widget.ayah ?? (saved.surah == widget.surah ? saved.ayah : 1);
    _positions.itemPositions.addListener(_onPositions);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positions.itemPositions.removeListener(_onPositions);
    for (final s in _subs) {
      s.cancel();
    }
    _audio?.dispose();
    super.dispose();
  }

  int _itemOfAyah(int ayah) => _headerCount + (_mode == _Mode.mushaf ? (ayah - 1) ~/ _chunkSize : ayah - 1);

  int _ayahOfItem(int item) {
    final i = item - _headerCount;
    if (i < 0) return 1;
    return _mode == _Mode.mushaf ? i * _chunkSize + 1 : i + 1;
  }

  int _itemCount(int total) => _headerCount + (_mode == _Mode.mushaf ? (total / _chunkSize).ceil() : total) + 1;

  /// Tracks the top ayah immediately and saves the bookmark and the pages
  /// that were on screen once scrolling settles.
  void _onPositions() {
    final visible = _positions.itemPositions.value.where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1).toList();
    if (visible.isEmpty) return;
    final first = visible.reduce((a, b) => a.index < b.index ? a : b);
    final last = visible.reduce((a, b) => a.index > b.index ? a : b);
    _topAyah = _ayahOfItem(first.index).clamp(1, 1 << 20);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final total = ref.read(ayahsProvider(widget.surah)).value?.length;
      if (total == null) return;
      final lastAyah = (_ayahOfItem(last.index) + (_mode == _Mode.mushaf ? _chunkSize - 1 : 0)).clamp(1, total);
      _save(_topAyah.clamp(1, total), lastAyah: lastAyah);
    });
  }

  /// Saves the bookmark and marks every mushaf page from [ayah] to [lastAyah] as read.
  void _save(int ayah, {int? lastAyah}) {
    final index = ref.read(quranIndexProvider).value;
    final from = index?.estimatePage(widget.surah, ayah);
    final to = index?.estimatePage(widget.surah, lastAyah ?? ayah);
    ref.read(readingProgressProvider.notifier).markRead(widget.surah, ayah, pages: from == null || to == null ? const [] : [for (var p = from; p <= to; p++) p]);
  }

  void _stopped() {
    if (mounted) setState(() => _playing = _started = false);
  }

  void _followAudio(int ayah) {
    final item = _itemOfAyah(ayah);
    if (item == _lastAutoItem || !_scroll.isAttached) return;
    _lastAutoItem = item;
    _scroll.scrollTo(index: item, alignment: .12, duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 400), curve: NoorMotion.curve);
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
        _followAudio(n);
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

  Future<void> _startFrom(int from, int total) async {
    final a = _player();
    _started = true;
    setState(() => _current = from);
    final prefs = ref.read(playbackPrefsProvider);
    await a.start(reciterId: ref.read(reciterProvider), surah: widget.surah, fromAyah: from, total: total);
    await a.setSpeed(prefs.speed);
    await a.setRepeatOne(prefs.repeatOne);
  }

  Future<void> _togglePlay(int total) async {
    HapticFeedback.lightImpact();
    final a = _player();
    if (_playing) return a.pause();
    if (_started) return a.resume();
    await _startFrom(_current >= total ? 1 : _current, total);
  }

  /// Previous / next ayah while a recitation is running, otherwise starts there.
  Future<void> _step(int delta, int total) async {
    HapticFeedback.selectionClick();
    final target = (_current + delta).clamp(1, total);
    if (_started) {
      setState(() => _current = target);
      await _player().skipTo(target);
    } else {
      await _startFrom(target, total);
    }
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

  void _onSpeed() {
    ref.read(playbackPrefsProvider.notifier).cycleSpeed();
    _audio?.setSpeed(ref.read(playbackPrefsProvider).speed);
  }

  void _onRepeat() {
    ref.read(playbackPrefsProvider.notifier).toggleRepeat();
    _audio?.setRepeatOne(ref.read(playbackPrefsProvider).repeatOne);
  }

  void _onTapAyah(Ayah a, int total) {
    setState(() => _current = a.number);
    _save(a.number);
    _openTafsir(context, a, total);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ayahs = ref.watch(ayahsProvider(widget.surah));
    final surah = ref.watch(quranIndexProvider).value?.surahs.where((s) => s.number == widget.surah).firstOrNull;
    final fs = ref.watch(settingsProvider.select((s) => s.quranFontSize));
    final prefs = ref.watch(playbackPrefsProvider);
    if (widget.autoplay && !_autoplayed && ayahs.value != null) {
      _autoplayed = true;
      final total = ayahs.value!.length;
      // Opening a surah from the Audio screen always starts from its first ayah.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startFrom(1, total);
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
              NoorIconButton(icon: Icons.text_decrease_rounded, tooltip: NoorFormat.tr(context, 'تصغير الخط', 'Smaller text'), onPressed: () => ref.read(settingsProvider.notifier).setQuranFontSize(fs - 2)),
              const SizedBox(width: 6),
              NoorIconButton(icon: Icons.text_increase_rounded, tooltip: NoorFormat.tr(context, 'تكبير الخط', 'Larger text'), onPressed: () => ref.read(settingsProvider.notifier).setQuranFontSize(fs + 2)),
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
              data: (list) => list == null ? _NotAvailable(message: NoorFormat.tr(context, 'هذه السورة غير موجودة.', 'This surah does not exist.')) : _body(context, list, surah, fs),
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
              speed: prefs.speed,
              repeatOne: prefs.repeatOne,
              onToggle: () => _togglePlay(ayahs.value!.length),
              onPrev: () => _step(-1, ayahs.value!.length),
              onNext: () => _step(1, ayahs.value!.length),
              onReciter: _pickReciter,
              onSpeed: _onSpeed,
              onRepeat: _onRepeat,
            ),
    );
  }

  Widget _body(BuildContext context, List<Ayah> list, Surah? surah, double fs) {
    final l = AppLocalizations.of(context);
    final mushaf = _mode == _Mode.mushaf;
    final chunks = (list.length / _chunkSize).ceil();
    final count = _itemCount(list.length);
    // A new key per mode rebuilds the list at the ayah the reader was looking at.
    return ScrollablePositionedList.builder(
      key: ValueKey(_mode),
      itemScrollController: _scroll,
      itemPositionsListener: _positions,
      initialScrollIndex: _itemOfAyah(_topAyah.clamp(1, list.length)).clamp(0, count - 1),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 190),
      itemCount: count,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(padding: const EdgeInsets.only(bottom: 14), child: _SurahHeader(nameAr: surah?.nameAr ?? ''));
        }
        if (_hasBasmala && i == 1) {
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_basmala, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: NoorText.quran(context, size: fs).copyWith(height: 1.8)));
        }
        final n = i - _headerCount;
        if (mushaf) {
          if (n >= chunks) return Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.translationSource, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall));
          final from = n * _chunkSize;
          final part = list.sublist(from, (from + _chunkSize).clamp(0, list.length));
          return _MushafChunk(
            key: ValueKey('c$n'),
            ayahs: part,
            fs: fs,
            activeAyah: _playing ? _current : null,
            first: n == 0,
            last: n == chunks - 1,
            onTap: (a) => _onTapAyah(a, list.length),
          );
        }
        if (n >= list.length) return Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.translationSource, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall));
        final a = list[n];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _AyahCard(
            ayah: a,
            fs: fs,
            active: _playing && a.number == _current,
            saved: _savedItem(a),
            onTafsir: () => _openTafsir(context, a, list.length),
            onCopy: () => _copy(context, a),
          ),
        );
      },
    );
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

  void _openTafsir(BuildContext context, Ayah a, int total) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final t = ctx.noor;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .85),
            child: SingleChildScrollView(
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
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _startFrom(a.number, total);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(NoorFormat.tr(ctx, 'استمع من هذه الآية', 'Listen from this ayah')),
                ),
                Row(spacing: 8, children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () => _copy(ctx, a), icon: const Icon(Icons.copy_rounded, size: 18), label: Text(l.copy))),
                  SaveButton(item: _savedItem(a), tooltip: l.save, size: 24),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}

String _arDigits(int n) => '$n'.replaceAllMapped(RegExp(r'\d'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)]);

/// A run of ayahs rendered as continuous mushaf text. Edges are drawn only on
/// the first and last chunk so the whole surah reads as one framed page.
class _MushafChunk extends StatefulWidget {
  const _MushafChunk({super.key, required this.ayahs, required this.fs, required this.activeAyah, required this.first, required this.last, required this.onTap});
  final List<Ayah> ayahs;
  final double fs;
  final int? activeAyah;
  final bool first, last;
  final ValueChanged<Ayah> onTap;

  @override
  State<_MushafChunk> createState() => _MushafChunkState();
}

class _MushafChunkState extends State<_MushafChunk> {
  late final List<TapGestureRecognizer> _recs;

  @override
  void initState() {
    super.initState();
    _recs = [for (final a in widget.ayahs) TapGestureRecognizer()..onTap = () => widget.onTap(a)];
  }

  @override
  void dispose() {
    for (final r in _recs) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final fs = widget.fs;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.ayahs.length; i++) {
      final a = widget.ayahs[i];
      final active = widget.activeAyah == a.number;
      spans.add(TextSpan(
        text: a.ar,
        recognizer: _recs[i],
        style: TextStyle(backgroundColor: active ? (dark ? const Color(0x2EE0C486) : const Color(0xFFF3E6C6)) : null),
        semanticsLabel: a.ar,
      ));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: EightPointStar(size: fs * 1.15, color: t.gold, child: Text(_arDigits(a.number), style: TextStyle(fontFamily: NoorFonts.display, fontSize: fs * .42, fontWeight: FontWeight.w700, color: t.goldText))),
        ),
      ));
      spans.add(const TextSpan(text: ' '));
    }
    final side = BorderSide(color: t.goldLine);
    return Container(
      padding: EdgeInsets.fromLTRB(18, widget.first ? 22 : 4, 18, widget.last ? 22 : 4),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(widget.first ? 22 : 0), bottom: Radius.circular(widget.last ? 22 : 0)),
        border: Border(left: side, right: side, top: widget.first ? side : BorderSide.none, bottom: widget.last ? side : BorderSide.none),
      ),
      child: Text.rich(TextSpan(children: spans), textDirection: TextDirection.rtl, textAlign: TextAlign.justify, style: NoorText.quran(context, size: fs).copyWith(height: 2.3)),
    );
  }
}

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.ayah, required this.fs, required this.active, required this.saved, required this.onTafsir, required this.onCopy});
  final Ayah ayah;
  final double fs;
  final bool active;
  final SavedItem saved;
  final VoidCallback onTafsir, onCopy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return NoorCard(
      borderColor: active ? t.gold : null,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: [
        Row(children: [
          Container(
            constraints: const BoxConstraints(minWidth: 30),
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: t.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Text(NoorFormat.digits(context, ayah.number), style: TextStyle(color: t.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
          const Spacer(),
          IconButton(tooltip: l.tafsir, icon: Icon(Icons.menu_book_outlined, size: 19, color: t.textSecondary), onPressed: onTafsir),
          IconButton(tooltip: l.copy, icon: Icon(Icons.copy_rounded, size: 19, color: t.textSecondary), onPressed: onCopy),
          SaveButton(item: saved, tooltip: l.save),
        ]),
        Text(ayah.ar, textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: NoorText.quran(context, size: fs).copyWith(height: 2.1)),
        Text(ayah.en, textDirection: TextDirection.ltr, textAlign: TextAlign.left, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 13.5, height: 1.6, color: t.textSecondary)),
      ]),
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
  const _PlayerBar({
    required this.playing,
    required this.current,
    required this.total,
    required this.reciterName,
    required this.speed,
    required this.repeatOne,
    required this.onToggle,
    required this.onPrev,
    required this.onNext,
    required this.onReciter,
    required this.onSpeed,
    required this.onRepeat,
  });
  final bool playing, repeatOne;
  final int current, total;
  final String reciterName;
  final double speed;
  final VoidCallback onToggle, onPrev, onNext, onReciter, onSpeed, onRepeat;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: t.border), boxShadow: t.cardShadow),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, spacing: 8, children: [
          NoorProgressBar(value: current / total, height: 3),
          Row(spacing: 10, children: [
            const IconBadge(icon: Icons.headphones_outlined, size: 38),
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
          ]),
          Row(spacing: 6, children: [
            ActionChip(
              label: Text('${speed == speed.roundToDouble() ? speed.toInt() : speed}×', style: TextStyle(fontFamily: NoorFonts.latinUi, fontWeight: FontWeight.w700, color: t.primary, fontSize: 12.5)),
              tooltip: NoorFormat.tr(context, 'سرعة التلاوة', 'Playback speed'),
              onPressed: onSpeed,
              backgroundColor: t.primarySoft,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: NoorFormat.tr(context, 'تكرار الآية', 'Repeat ayah'),
              isSelected: repeatOne,
              onPressed: onRepeat,
              style: IconButton.styleFrom(backgroundColor: repeatOne ? t.primarySoft : Colors.transparent, fixedSize: const Size(44, 44)),
              icon: Icon(repeatOne ? Icons.repeat_one_rounded : Icons.repeat_rounded, color: repeatOne ? t.primary : t.textSecondary, size: 22),
            ),
            const Spacer(),
            IconButton(tooltip: NoorFormat.tr(context, 'الآية السابقة', 'Previous ayah'), onPressed: current > 1 ? onPrev : null, style: IconButton.styleFrom(fixedSize: const Size(44, 44)), icon: const Icon(Icons.skip_previous_rounded, size: 26)),
            IconButton.filled(
              tooltip: playing ? l.pause : l.play,
              style: IconButton.styleFrom(backgroundColor: t.primary, foregroundColor: t.onPrimary, fixedSize: const Size(52, 52)),
              onPressed: onToggle,
              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
            ),
            IconButton(tooltip: NoorFormat.tr(context, 'الآية التالية', 'Next ayah'), onPressed: current < total ? onNext : null, style: IconButton.styleFrom(fixedSize: const Size(44, 44)), icon: const Icon(Icons.skip_next_rounded, size: 26)),
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
