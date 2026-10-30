import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../../l10n/app_localizations.dart';
import 'data/location_service.dart';
import 'data/place_names.dart';
import 'domain/prayer_cities.dart';
import 'domain/prayer_models.dart';
import 'prayer_providers.dart';

Future<void> showLocationSheet(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => const LocationSheet());

/// "28.4328° N, 45.9627° E" (Arabic digits and letters in Arabic).
String formatCoordinates(BuildContext context, double lat, double lng) {
  final ar = NoorFormat.isAr(context);
  String part(double v, String pos, String neg) => '${NoorFormat.digits(context, v.abs().toStringAsFixed(4))}° ${v >= 0 ? pos : neg}';
  return ar ? '${part(lat, 'ش', 'ج')}، ${part(lng, 'ق', 'غ')}' : '${part(lat, 'N', 'S')}, ${part(lng, 'E', 'W')}';
}

/// "٧٠ دقيقة" / "3 hours": how old a remembered position is.
String _age(BuildContext context, Duration d) {
  if (d.inMinutes < 120) return NoorFormat.tr(context, '${NoorFormat.digits(context, d.inMinutes)} دقيقة', '${d.inMinutes} min');
  return NoorFormat.tr(context, '${NoorFormat.digits(context, d.inHours)} ساعة', '${d.inHours} h');
}

class LocationSheet extends ConsumerStatefulWidget {
  const LocationSheet({super.key});
  @override
  ConsumerState<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<LocationSheet> {
  String _query = '';
  bool _busy = false;
  bool _searching = false;
  List<PlaceHit>? _hits; // null = no map search run for the current query
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _useDevice() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    final failure = await ref.read(prayerLocationProvider.notifier).useDeviceLocation();
    if (!mounted) return;
    setState(() => _busy = false);
    if (failure == null) {
      final loc = ref.read(prayerLocationProvider);
      final ctrl = ref.read(prayerLocationProvider.notifier);
      final name = NoorFormat.isAr(context) ? loc.nameAr : loc.nameEn;
      final String text;
      if (ctrl.lastFixStale) {
        // The signal was too weak for a new fix (indoors): say so, and how old the position is.
        text = NoorFormat.tr(
          context,
          '$name — من آخر موقع معروف قبل ${_age(context, ctrl.lastFixAge)} لضعف الإشارة. اخرج إلى مكان مفتوح واضغط «تحديد موقعي الآن» لتحديث أدق.',
          '$name — from the last known position, ${_age(context, ctrl.lastFixAge)} ago, because the signal is weak. Go outside and tap “Locate me now” for a fresh fix.',
        );
      } else {
        final m = ctrl.lastFixAccuracy;
        text = m == null || m <= 0 ? '${l.locationUpdated}: $name' : '${l.locationUpdated}: $name (${NoorFormat.tr(context, 'دقة ±${NoorFormat.digits(context, m.round())} م', '±${m.round()} m')})';
      }
      nav.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text, textAlign: TextAlign.center), duration: Duration(seconds: ctrl.lastFixStale ? 9 : 4)));
      return;
    }
    final message = switch (failure) {
      LocationFailure.serviceOff => l.locServiceOff,
      LocationFailure.denied => l.locDenied,
      LocationFailure.deniedForever => l.locDeniedForever,
      LocationFailure.unavailable => l.locUnavailable,
    };
    // Say what to do about it: open the right system screen, or simply try again.
    final fixInSettings = failure == LocationFailure.serviceOff || failure == LocationFailure.deniedForever;
    final action = SnackBarAction(
      label: fixInSettings
          ? (failure == LocationFailure.serviceOff ? NoorFormat.tr(context, 'تفعيل الموقع', 'Turn on') : NoorFormat.tr(context, 'فتح الإعدادات', 'Open settings'))
          : NoorFormat.tr(context, 'حاول مجددًا', 'Try again'),
      onPressed: () => fixInSettings ? ref.read(openLocationSettingsProvider)(failure) : _useDevice(),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action, duration: const Duration(seconds: 8)));
  }

  void _onQuery(String v) {
    setState(() {
      _query = v.trim();
      _hits = null;
    });
    _debounce?.cancel();
    // Search the map only when the built-in list has nothing, after typing pauses.
    if (_query.runes.length >= 2 && _localMatches().isEmpty) {
      _debounce = Timer(const Duration(milliseconds: 600), _searchMap);
    }
  }

  List<PrayerLocation> _localMatches() {
    final q = _query.toLowerCase();
    return prayerCities.where((c) => q.isEmpty || c.nameAr.contains(_query) || c.nameEn.toLowerCase().contains(q)).toList();
  }

  Future<void> _searchMap() async {
    final q = _query;
    if (q.runes.length < 2) return;
    setState(() => _searching = true);
    final hits = await ref.read(placeNamerProvider).search(q);
    if (!mounted || q != _query) return;
    setState(() {
      _searching = false;
      _hits = hits;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    final current = ref.watch(prayerLocationProvider);
    final cities = _localMatches();
    final hits = _hits ?? const <PlaceHit>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.changeLocation, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              // Where times are calculated now, precisely.
              NoorCard(
                color: t.primarySoft,
                borderColor: t.primaryLine,
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Row(spacing: 12, children: [
                  Icon(current.fromDevice ? Icons.my_location_rounded : Icons.location_city_rounded, color: t.primary),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                      Text(NoorFormat.tr(context, 'الموقع الحالي للمواقيت', 'Prayer times are for'), style: Theme.of(context).textTheme.bodySmall),
                      Text(ar ? current.nameAr : current.nameEn, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                      Text(formatCoordinates(context, current.latitude, current.longitude), textDirection: ar ? TextDirection.rtl : TextDirection.ltr, style: TextStyle(fontSize: 12, color: t.textSecondary)),
                    ]),
                  ),
                  if (_busy)
                    const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4)))
                  else
                    IconButton(
                      tooltip: NoorFormat.tr(context, 'تحديد موقعي الآن', 'Locate me now'),
                      onPressed: _useDevice,
                      icon: Icon(Icons.gps_fixed_rounded, color: t.primary),
                    ),
                ]),
              ),
              const SizedBox(height: 10),
              NoorCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: _busy ? null : _useDevice,
                child: Row(spacing: 12, children: [
                  const IconBadge(icon: Icons.my_location_rounded, solid: true, size: 38),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 2, children: [
                      Text(l.useMyLocation, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(NoorFormat.tr(context, 'تحديد دقيق باسم مدينتك، ويتحدّث تلقائيًا إذا انتقلت', 'Precise, with your city’s name; updates when you move'), style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              NoorSearchField(hint: NoorFormat.tr(context, 'ابحث عن أي مدينة في العالم', 'Search any city in the world'), onChanged: _onQuery),
              const SizedBox(height: 6),
              Expanded(
                child: ListView(children: [
                  for (final c in cities)
                    ListTile(
                      minTileHeight: 52,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                      selected: c == current,
                      selectedColor: t.primary,
                      title: Text(ar ? c.nameAr : c.nameEn, style: TextStyle(fontWeight: c == current ? FontWeight.w700 : FontWeight.w500)),
                      trailing: c == current ? Icon(Icons.check_rounded, color: t.primary) : null,
                      onTap: () {
                        ref.read(prayerLocationProvider.notifier).select(c);
                        Navigator.of(context).pop();
                      },
                    ),
                  if (_query.runes.length >= 2) ...[
                    if (cities.isNotEmpty && _hits == null && !_searching)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        leading: Icon(Icons.travel_explore_rounded, color: t.primary),
                        title: Text(NoorFormat.tr(context, 'ابحث عن «$_query» على الخريطة', 'Search the map for “$_query”'), style: TextStyle(color: t.primary, fontWeight: FontWeight.w600)),
                        onTap: _searchMap,
                      ),
                    if (_searching) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
                    if (_hits != null && hits.isEmpty && !_searching)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(NoorFormat.tr(context, 'لم يُعثر على «$_query». تحقق من الاتصال أو جرّب اسمًا آخر.', 'Nothing found for “$_query”. Check your connection or try another name.'), textAlign: TextAlign.center, style: TextStyle(color: t.textSecondary)),
                      ),
                    for (final h in hits)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                        leading: Icon(Icons.place_outlined, color: t.primary),
                        title: Text(ar ? h.name.ar : h.name.en, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(formatCoordinates(context, h.latitude, h.longitude)),
                        onTap: () {
                          ref.read(prayerLocationProvider.notifier).selectPlace(h);
                          Navigator.of(context).pop();
                        },
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      NoorFormat.tr(context, 'المدن المدرجة تُعرض بتوقيتها المحلي. موقعك الحالي والمدن من الخريطة تُعرض بتوقيت جهازك.', 'Listed cities show their own local time. Your location and places from the map use your device’s time zone.'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
