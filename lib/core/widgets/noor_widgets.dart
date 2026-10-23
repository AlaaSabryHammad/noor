import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/noor_theme.dart';
import '../theme/noor_tokens.dart';

/// White (light) / surface (dark) card with hairline border and soft shadow.
class NoorCard extends StatelessWidget {
  const NoorCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color, this.borderColor, this.radius = NoorRadius.card, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: borderColor ?? t.border));
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: t.cardShadow),
      child: Material(
        color: color ?? t.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Deep-green gradient surface with the eight-point-star pattern.
class HeroSurface extends StatelessWidget {
  const HeroSurface({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = NoorRadius.hero, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x66064E45), blurRadius: 44, spreadRadius: -22, offset: Offset(0, 22))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(gradient: t.heroGradient),
            child: InkWell(
              onTap: onTap,
              child: CustomPaint(
                painter: const StarPatternPainter(color: Color(0x1AFFFFFF)),
                child: DefaultTextStyle.merge(style: const TextStyle(color: NoorTokens.onHero), child: Padding(padding: padding, child: child)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Repeating khatam (two overlapping squares) — the NOOR signature motif.
class StarPatternPainter extends CustomPainter {
  const StarPatternPainter({required this.color, this.cell = 44});
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9;
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        final c = Offset(x + cell / 2, y + cell / 2);
        final s = cell * .18;
        canvas.drawRect(Rect.fromCenter(center: c, width: s * 2, height: s * 2), p);
        final d = s * math.sqrt2;
        canvas.drawPath(Path()
          ..moveTo(c.dx, c.dy - d)
          ..lineTo(c.dx + d, c.dy)
          ..lineTo(c.dx, c.dy + d)
          ..lineTo(c.dx - d, c.dy)
          ..close(), p);
      }
    }
  }

  @override
  bool shouldRepaint(StarPatternPainter old) => old.color != color;
}

/// 8-point star outline (used for ayah markers and surah numbers).
class EightPointStar extends StatelessWidget {
  const EightPointStar({super.key, required this.size, required this.color, this.child, this.strokeWidth = 1.1});
  final double size;
  final Color color;
  final Widget? child;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _StarPainter(color, strokeWidth), child: Center(child: child)),
      );
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.color, this.sw);
  final Color color;
  final double sw;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - sw;
    // Inner vertices of a square ∪ rotated square: r·cos45°/cos22.5°.
    final inner = r * math.cos(math.pi / 4) / math.cos(math.pi / 8);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round;
    // Union of square and diamond outline = 16 points.
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final a = -math.pi / 2 + i * math.pi / 8;
      final rad = i.isEven ? r : inner;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

/// 44×44 icon button with hairline border.
class NoorIconButton extends StatelessWidget {
  const NoorIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.filled = false, this.badge = false, this.child});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final bool badge;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: filled ? t.primary : t.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm), side: BorderSide(color: filled ? t.primary : t.border)),
          child: InkWell(
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm)),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 44,
              child: Stack(alignment: Alignment.center, children: [
                child ?? Icon(icon, size: 21, color: filled ? t.onPrimary : t.text),
                if (badge)
                  PositionedDirectional(
                    top: 10,
                    end: 11,
                    child: Container(width: 8, height: 8, decoration: BoxDecoration(color: t.gold, shape: BoxShape.circle, border: Border.all(color: t.surface, width: 1.5))),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Directional back button (mirrors in RTL automatically).
class NoorBackButton extends StatelessWidget {
  const NoorBackButton({super.key});
  @override
  Widget build(BuildContext context) => NoorIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.of(context).maybePop(),
      );
}

class NoorProgressBar extends StatelessWidget {
  const NoorProgressBar({super.key, required this.value, this.color, this.track, this.height = 6});
  final double value;
  final Color? color;
  final Color? track;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: track ?? t.sunk)),
          FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: value.clamp(0, 1),
            child: AnimatedContainer(duration: context.reduceMotion ? Duration.zero : NoorMotion.enter, decoration: BoxDecoration(color: color ?? t.primary, borderRadius: BorderRadius.circular(height))),
          ),
        ]),
      ),
    );
  }
}

/// Pill segmented control (equal-width segments).
class NoorSegmented<T> extends StatelessWidget {
  const NoorSegmented({super.key, required this.values, required this.labels, required this.selected, required this.onChanged, this.dense = false});
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.sunk, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: Semantics(
              selected: values[i] == selected,
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(values[i]);
                },
                child: AnimatedContainer(
                  duration: NoorMotion.press,
                  height: dense ? 34 : 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: values[i] == selected ? t.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: values[i] == selected ? const [BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1))] : null,
                  ),
                  child: Text(labels[i],
                      style: TextStyle(fontSize: 13, fontWeight: values[i] == selected ? FontWeight.w700 : FontWeight.w500, color: values[i] == selected ? t.text : t.textSecondary)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

class NoorSearchField extends StatelessWidget {
  const NoorSearchField({super.key, required this.hint, this.onChanged});
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.textSecondary, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded, color: t.textSecondary, size: 20),
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: t.primary, width: 1.5)),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
        ?trailing,
      ]);
}

/// Screen title in the display face (Amiri).
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.size = 30});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text(text, style: NoorText.display(context, size: size), semanticsLabel: text);
}

/// Icon in a tinted rounded square.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.gold = false, this.size = 42, this.solid = false});
  final IconData icon;
  final bool gold;
  final bool solid;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final bg = solid ? t.primary : (gold ? t.goldSoft : t.primarySoft);
    final fg = solid ? t.onPrimary : (gold ? t.goldText : t.primary);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .33)),
      child: Icon(icon, color: fg, size: size * .5),
    );
  }
}

class NoorPrimaryButton extends StatelessWidget {
  const NoorPrimaryButton({super.key, required this.label, required this.onPressed, this.soft = false});
  final String label;
  final VoidCallback? onPressed;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: soft ? t.primarySoft : t.primary,
        foregroundColor: soft ? t.primary : t.onPrimary,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NoorRadius.sm)),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

void showNoorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message, textAlign: TextAlign.center), duration: const Duration(milliseconds: 2200)));
}
