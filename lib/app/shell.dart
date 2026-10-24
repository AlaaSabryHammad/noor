import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/noor_tokens.dart';
import '../core/widgets/adaptive.dart';
import '../features/audio/audio_widgets.dart';
import '../features/audio/quran_player.dart';
import '../l10n/app_localizations.dart';

/// Height the mini player adds above the navigation bar while audio is loaded.
const _miniPlayerSpace = 72.0;

typedef _NavItem = (IconData, IconData, String);

/// Floating, blurred five-item navigation (Home, Quran, Prayer, Adhkar, Explore):
/// a bottom bar on phones, a side rail on wide screens (tablets, landscape),
/// with the mini player stacked above the bar or under the content while
/// something is playing.
class NoorShell extends ConsumerWidget {
  const NoorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final listening = ref.watch(quranPlayerProvider.select((s) => s.current != null));
    final items = <_NavItem>[
      (Icons.home_outlined, Icons.home_rounded, l.navHome),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, l.navQuran),
      (Icons.mosque_outlined, Icons.mosque_rounded, l.navPrayer),
      (Icons.blur_circular_outlined, Icons.blur_circular_rounded, l.navAdhkar),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l.navExplore),
    ];
    final miniPlayer = DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: t.cardShadow), child: const MiniPlayer());

    if (NoorLayout.isWide(context)) {
      // The rail sits on the start side (right in Arabic) and owns that edge's safe-area inset.
      final railOnLeft = Directionality.of(context) == TextDirection.ltr;
      return Scaffold(
        body: Row(children: [
          SafeArea(
            left: railOnLeft,
            right: !railOnLeft,
            child: Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 14), child: _Rail(items: items, shell: shell)),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeLeft: railOnLeft,
              removeRight: !railOnLeft,
              child: Column(children: [
                Expanded(child: shell),
                if (listening)
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 560), child: miniPlayer),
                  ),
              ]),
            ),
          ),
        ]),
      );
    }

    return Scaffold(
      extendBody: true,
      // Screens pad their lists for the floating bar; lift them by the mini player's height too.
      body: Padding(padding: EdgeInsets.only(bottom: listening ? _miniPlayerSpace : 0), child: shell),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (listening) Padding(padding: const EdgeInsets.only(bottom: 8), child: miniPlayer),
          _Frosted(
            height: 72,
            child: Row(children: [
              for (var i = 0; i < items.length; i++) Expanded(child: _NavButton(item: items[i], index: i, shell: shell)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// The vertical bar for wide screens: same buttons, stacked and centred.
class _Rail extends StatelessWidget {
  const _Rail({required this.items, required this.shell});
  final List<_NavItem> items;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => _Frosted(
        width: 84,
        child: Center(
          // Phones in landscape are short: scroll rather than overflow.
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(mainAxisSize: MainAxisSize.min, spacing: 4, children: [
              for (var i = 0; i < items.length; i++) SizedBox(height: 64, child: _NavButton(item: items[i], index: i, shell: shell)),
            ]),
          ),
        ),
      );
}

/// Blurred, bordered surface shared by the bar and the rail. The size is the
/// outer size, border included.
class _Frosted extends StatelessWidget {
  const _Frosted({required this.child, this.width, this.height});
  final Widget child;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: t.navBackground, borderRadius: BorderRadius.circular(26), border: Border.all(color: t.border)),
          // Fixed-size buttons, so labels scale only a little with system text size.
          child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.15, child: child),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.index, required this.shell});
  final _NavItem item;
  final int index;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final selected = shell.currentIndex == index;
    return Semantics(
      selected: selected,
      button: true,
      label: item.$3,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          shell.goBranch(index, initialLocation: selected);
        },
        child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 4, children: [
          AnimatedContainer(
            duration: NoorMotion.press,
            width: 56,
            height: 30,
            decoration: BoxDecoration(color: selected ? t.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(99)),
            child: Icon(selected ? item.$2 : item.$1, size: 22, color: selected ? t.primary : t.textSecondary),
          ),
          Text(item.$3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? t.primary : t.textSecondary)),
        ]),
      ),
    );
  }
}
