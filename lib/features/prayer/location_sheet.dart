import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'data/location_service.dart';
import 'domain/prayer_cities.dart';
import 'prayer_providers.dart';

Future<void> showLocationSheet(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const LocationSheet());

class LocationSheet extends ConsumerStatefulWidget {
  const LocationSheet({super.key});
  @override
  ConsumerState<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<LocationSheet> {
  String _query = '';
  bool _busy = false;

  Future<void> _useDevice() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    final failure = await ref.read(prayerLocationProvider.notifier).useDeviceLocation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      nav.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.locationUpdated, textAlign: TextAlign.center)));
      return;
    }
    showNoorSnack(
      context,
      switch (failure) {
        LocationFailure.serviceOff => l.locServiceOff,
        LocationFailure.denied => l.locDenied,
        LocationFailure.deniedForever => l.locDeniedForever,
        LocationFailure.unavailable => l.locUnavailable,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final current = ref.watch(prayerLocationProvider);
    final q = _query.toLowerCase();
    final cities = prayerCities.where((c) => q.isEmpty || c.nameAr.contains(_query) || c.nameEn.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.changeLocation, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            NoorSearchField(hint: l.searchCity, onChanged: (v) => setState(() => _query = v.trim())),
            const SizedBox(height: 10),
            NoorCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: _busy ? null : _useDevice,
              child: Row(spacing: 12, children: [
                const IconBadge(icon: Icons.my_location_rounded, solid: true, size: 38),
                Expanded(child: Text(l.useMyLocation, style: const TextStyle(fontWeight: FontWeight.w600))),
                if (_busy) const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
              ]),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cities.length + 1,
                itemBuilder: (context, i) {
                  if (i == cities.length) {
                    return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(l.locationCitiesNote, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall));
                  }
                  final c = cities[i];
                  final selected = c == current;
                  return ListTile(
                    minTileHeight: 52,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    selected: selected,
                    selectedColor: t.primary,
                    title: Text(ar ? c.nameAr : c.nameEn, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                    trailing: selected ? Icon(Icons.check_rounded, color: t.primary) : null,
                    onTap: () {
                      ref.read(prayerLocationProvider.notifier).select(c);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
      ),
    );
  }
}
