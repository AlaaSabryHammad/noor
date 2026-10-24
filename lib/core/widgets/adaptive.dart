import 'package:flutter/material.dart';

/// Screen-size rules. Phones keep the original single column; from
/// [wideFrom] (tablets, phones in landscape) the shell swaps the bottom bar
/// for a side rail and content sits in a centred column.
abstract final class NoorLayout {
  static const wideFrom = 600.0;

  /// Widest content column: readable lines and cards that don't stretch.
  static const column = 760.0;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideFrom;

  /// Room under a tab's list for the floating bottom bar; the side rail needs none.
  static double navClearance(BuildContext context) => isWide(context) ? 32 : 120;

  /// [base] with its sides grown so the content between them is at most
  /// [max] wide inside a view [width] wide.
  static EdgeInsets centered(EdgeInsets base, double width, {double max = column}) {
    final extra = ((width - base.horizontal - max) / 2).clamp(0.0, double.infinity);
    return base.copyWith(left: base.left + extra, right: base.right + extra);
  }
}

/// A [ListView] whose content sits in a centred column at most [maxWidth]
/// wide. The view itself stays full width, so it scrolls from the margins too.
class ColumnListView extends StatelessWidget {
  const ColumnListView({super.key, required this.padding, required List<Widget> this.children, this.controller, this.maxWidth = NoorLayout.column})
      : itemCount = null,
        itemBuilder = null;

  const ColumnListView.builder({super.key, required this.padding, required int this.itemCount, required IndexedWidgetBuilder this.itemBuilder, this.controller, this.maxWidth = NoorLayout.column})
      : children = null;

  final EdgeInsetsGeometry padding;
  final List<Widget>? children;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final ScrollController? controller;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final p = NoorLayout.centered(padding.resolve(Directionality.of(context)), box.maxWidth, max: maxWidth);
        final build = itemBuilder;
        return build == null ? ListView(controller: controller, padding: p, children: children!) : ListView.builder(controller: controller, padding: p, itemCount: itemCount, itemBuilder: build);
      });
}

/// A [SliverPadding] that centres [sliver] in a column at most [maxWidth] wide.
class SliverColumn extends StatelessWidget {
  const SliverColumn({super.key, required this.padding, required this.sliver, this.maxWidth = NoorLayout.column});
  final EdgeInsetsGeometry padding;
  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
        builder: (context, c) => SliverPadding(padding: NoorLayout.centered(padding.resolve(Directionality.of(context)), c.crossAxisExtent, max: maxWidth), sliver: sliver),
      );
}

/// [child] inside [padding], centred so the content is at most [maxWidth]
/// wide: fixed headers above a list line up with the list's column.
class ContentColumn extends StatelessWidget {
  const ContentColumn({super.key, required this.child, this.padding = EdgeInsets.zero, this.maxWidth = NoorLayout.column});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth + padding.horizontal),
          child: Padding(padding: padding, child: child),
        ),
      );
}
