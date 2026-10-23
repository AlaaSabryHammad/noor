import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/noor_tokens.dart';
import '../l10n/app_localizations.dart';

/// Floating, blurred five-item bottom navigation (Home, Quran, Prayer, Adhkar, Explore).
class NoorShell extends StatelessWidget {
  const NoorShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, l.navHome),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, l.navQuran),
      (Icons.mosque_outlined, Icons.mosque_rounded, l.navPrayer),
      (Icons.blur_circular_outlined, Icons.blur_circular_rounded, l.navAdhkar),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l.navExplore),
    ];
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 72,
              decoration: BoxDecoration(color: t.navBackground, borderRadius: BorderRadius.circular(26), border: Border.all(color: t.border)),
              // The bar has a fixed height, so its labels scale only a little with system text size.
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.15,
                child: Row(children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      selected: shell.currentIndex == i,
                      button: true,
                      label: items[i].$3,
                      excludeSemantics: true,
                      child: InkResponse(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          shell.goBranch(i, initialLocation: i == shell.currentIndex);
                        },
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, spacing: 4, children: [
                          AnimatedContainer(
                            duration: NoorMotion.press,
                            width: 56,
                            height: 30,
                            decoration: BoxDecoration(color: shell.currentIndex == i ? t.primarySoft : Colors.transparent, borderRadius: BorderRadius.circular(99)),
                            child: Icon(shell.currentIndex == i ? items[i].$2 : items[i].$1, size: 22, color: shell.currentIndex == i ? t.primary : t.textSecondary),
                          ),
                          Text(items[i].$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: shell.currentIndex == i ? FontWeight.w700 : FontWeight.w500, color: shell.currentIndex == i ? t.primary : t.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
              ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
