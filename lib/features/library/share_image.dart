import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import 'favorites.dart';

/// Looks of the shareable card.
enum ShareCardStyle { emerald, ivory, night }

/// Opens a preview of [item] as an image card, then the system share sheet.
class ShareImageButton extends StatelessWidget {
  const ShareImageButton({super.key, required this.item, this.size = 19});
  final SavedItem item;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: NoorFormat.tr(context, 'مشاركة كصورة', 'Share as image'),
        icon: Icon(Icons.image_outlined, size: size, color: context.noor.textSecondary),
        onPressed: () => showShareImageSheet(context, item),
      );
}

Future<void> showShareImageSheet(BuildContext context, SavedItem item) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ShareSheet(item: item),
    );

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.item});
  final SavedItem item;
  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _card = GlobalKey();
  ShareCardStyle _style = ShareCardStyle.emerald;
  bool _translation = false;
  bool _busy = false;

  Future<void> _share(Rect origin) async {
    setState(() => _busy = true);
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/noor_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')], sharePositionOrigin: origin));
    } catch (e) {
      if (mounted) showNoorSnack(context, NoorFormat.tr(context, 'تعذّرت المشاركة.', 'Couldn’t share.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: [
            Text(NoorFormat.tr(context, 'مشاركة كصورة', 'Share as image'), style: Theme.of(context).textTheme.titleMedium),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: RepaintBoundary(key: _card, child: ShareCard(item: widget.item, style: _style, translation: _translation)),
              ),
            ),
            NoorSegmented<ShareCardStyle>(
              values: ShareCardStyle.values,
              labels: [NoorFormat.tr(context, 'زمرّدي', 'Emerald'), NoorFormat.tr(context, 'عاجي', 'Ivory'), NoorFormat.tr(context, 'ليلي', 'Night')],
              selected: _style,
              dense: true,
              onChanged: (v) => setState(() => _style = v),
            ),
            if (widget.item.translation.isNotEmpty)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _translation,
                onChanged: (v) => setState(() => _translation = v),
                title: Text(ar ? 'إظهار الترجمة الإنجليزية' : 'Show the English translation'),
                activeThumbColor: t.primary,
              ),
            Builder(
              builder: (bctx) => FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: t.primary, foregroundColor: t.onPrimary, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm))),
                onPressed: _busy
                    ? null
                    : () {
                        final box = bctx.findRenderObject()! as RenderBox;
                        _share(box.localToGlobal(Offset.zero) & box.size);
                      },
                icon: _busy ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: t.onPrimary)) : const Icon(Icons.ios_share_rounded),
                label: Text(NoorFormat.tr(context, 'مشاركة', 'Share')),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A 4:5 card (fits stories and feeds) with the khatam pattern, the text,
/// its source and the app's mark. Long texts shrink to fit.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.item, this.style = ShareCardStyle.emerald, this.translation = false});
  final SavedItem item;
  final ShareCardStyle style;
  final bool translation;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, accent, pattern) = switch (style) {
      ShareCardStyle.emerald => (const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0B7565), Color(0xFF075E54), Color(0xFF053E37)]), Colors.white, NoorTokens.onHeroAccent, const Color(0x1AFFFFFF)),
      ShareCardStyle.ivory => (const LinearGradient(colors: [Color(0xFFFBF7EE), Color(0xFFF3EBD9)]), const Color(0xFF1C2B29), const Color(0xFF9A7428), const Color(0x149A7428)),
      ShareCardStyle.night => (const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF14211F), Color(0xFF0B1413)]), const Color(0xFFF1EBDD), NoorTokens.onHeroAccent, const Color(0x14E0C486)),
    };
    final quranic = item.kind == 'ayah';
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: bg, borderRadius: BorderRadius.circular(20)),
            child: CustomPaint(
              painter: StarPatternPainter(color: pattern, cell: 36),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                child: Column(children: [
                  EightPointStar(size: 30, color: accent, strokeWidth: 1.2),
                  const SizedBox(height: 10),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: c.maxWidth,
                            child: Column(mainAxisSize: MainAxisSize.min, spacing: 12, children: [
                              Text(
                                quranic ? '﴿ ${item.body} ﴾' : item.body,
                                textAlign: TextAlign.center,
                                style: quranic ? NoorText.quran(context, size: 22, color: fg).copyWith(height: 2) : TextStyle(fontFamily: NoorFonts.display, fontSize: 20, height: 1.9, color: fg),
                              ),
                              if (translation && item.translation.isNotEmpty)
                                Text(item.translation, textAlign: TextAlign.center, textDirection: TextDirection.ltr, style: TextStyle(fontFamily: NoorFonts.latinUi, fontSize: 12, height: 1.5, color: fg.withValues(alpha: .8), fontStyle: FontStyle.italic)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (item.source.isNotEmpty) Text(item.source, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontFamily: NoorFonts.arabicUi, fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                  const SizedBox(height: 8),
                  Text('نور · NOOR', style: TextStyle(fontFamily: NoorFonts.arabicUi, fontSize: 10.5, letterSpacing: .5, color: fg.withValues(alpha: .6))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
