import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets/adaptive.dart';
import '../../core/widgets/noor_widgets.dart';

/// Parsed `assets/data/<name>.json`. Content stays out of the widget tree so
/// it can be swapped for downloadable content later.
final contentJsonProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, name) async {
  final raw = await ref.watch(contentLoaderProvider)('assets/data/$name.json');
  return jsonDecode(raw) as Map<String, dynamic>;
});

/// Common frame for the service screens: back button, centred title, list body.
class ServiceScaffold extends StatelessWidget {
  const ServiceScaffold({super.key, required this.title, required this.children, this.trailing, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 30)});
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ColumnListView(padding: padding, children: [
            Row(children: [
              const NoorBackButton(),
              Expanded(child: Center(child: ScreenTitle(title, size: 22))),
              trailing ?? const SizedBox(width: 44),
            ]),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );
}

/// Loading / error wrapper for [contentJsonProvider] consumers.
Widget contentBody(AsyncValue<Map<String, dynamic>> v, Widget Function(Map<String, dynamic> data) builder) => v.when(
      loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('$e'))),
      data: builder,
    );

/// Picks `<base>Ar` or `<base>En` from a content map.
String pick(Map<String, dynamic> m, String base, bool ar) => (m[ar ? '${base}Ar' : '${base}En'] ?? m['${base}Ar'] ?? '') as String;
