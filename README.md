# NOOR | نور

Premium Islamic super app — Flutter (Android + iOS). Arabic-first (RTL), English (LTR), light mode by default with an independently designed dark mode. Built from the NOOR design canvas.

## Run

```bash
flutter pub get
flutter gen-l10n        # also runs automatically on build (generate: true)
flutter run
flutter test            # 21 tests: prayer engine, app smoke, screenshots
flutter test test/screens --update-goldens   # re-render screen PNGs in test/screens/shots
```

Tested with Flutter 3.47.7 / Dart 3.13.

## What works today

| Area | Status |
|---|---|
| Design system | `NoorTokens` ThemeExtension (light/dark), palette, spacing/radius/motion tokens, bundled fonts (Amiri Quran, Amiri, IBM Plex Sans Arabic, Plus Jakarta Sans) — fully offline |
| Localization | ARB `ar` (default) + `en`, automatic RTL/LTR, Arabic-Indic digits in Arabic UI, Umm al-Qura Hijri date |
| Home | Greeting (Friday-aware), Hijri + Gregorian date, live next-prayer hero with countdown, Friday sunnah card, continue reading + khatma ring, quick access, morning adhkar progress, Daily light (ayah / hadith / dua) with copy |
| Prayer | Real on-device calculation (`adhan`, Umm al-Qura, standard Asr), sun-path dial, per-prayer alert toggles (persisted), Qibla bearing |
| Qibla | Animated compass rose, Kaaba marker, turn-left/right guidance, haptic on alignment. **Heading is simulated** (slider) until a compass sensor is wired |
| Quran | Surah index (search), Juz grid, reader in Mushaf mode (tap ayah → tafsir sheet) and Translation mode, font size (persisted), simulated recitation with ayah highlighting, copy with surah/ayah reference |
| Adhkar | Categories, morning session with per-dhikr counters, progress, daily reset, completion state, sources shown |
| Tasbeeh | 33-bead ring, 5 phrases, targets 33/99/100, today/all-time stats, haptics, persisted |
| Explore | All services grouped; unbuilt ones open a placeholder |
| Settings | Language, Light/Dark/System (persisted) |

## Architecture

```
lib/
  app/            app.dart (MaterialApp.router), router.dart (go_router, StatefulShellRoute), shell.dart (floating nav)
  core/
    theme/        noor_colors, noor_tokens (ThemeExtension), noor_theme
    widgets/      NoorCard, HeroSurface, StarPatternPainter, EightPointStar, NoorSegmented, NoorProgressBar …
    utils/        noor_format (digits, 12h time, countdown, Hijri)
    providers.dart  sharedPreferences, clock, contentLoader
  features/<feature>/  domain → data (repository interfaces + impls) → providers → screens
  l10n/           app_ar.arb, app_en.arb (+ generated)
assets/
  fonts/          bundled fonts (OFL)
  data/           SAMPLE content: quran_sample.json, adhkar.json, daily.json
```

State: Riverpod 3 (`Notifier`, `FutureProvider`). Persistence: SharedPreferences (swap for Isar/SQLite as data grows). Everything personal stays on device.

## Before release — required

1. **Quran text**: `quran_sample.json` holds Al-Fatihah + 12 surah index rows only. Import the full verified Uthmani text (KFGQPC Madinah Mushaf or Tanzil) into a local DB behind `QuranRepository`.
2. **Adhkar & hadith**: texts are hand-entered from well-known sources; verify wording and hadith numbering against a scholar-reviewed dataset.
3. **Tafsir**: UI shows a placeholder; load verbatim from a licensed source (e.g. Al-Muyassar).
4. **Location**: replace `prayerLocationProvider` (fixed to Dammam) with `geolocator` + manual city picker; add high-latitude rule selection.
5. **Compass**: replace `headingProvider` with `flutter_compass` (expose accuracy → calibration prompt).
6. **Audio**: replace the simulated recitation with `just_audio` + per-ayah timing data; background playback via `audio_service`.
7. **Notifications**: schedule adhan alerts from `prayerAlertsProvider` with `flutter_local_notifications` (exact alarms on Android).
8. **Ramadan**: Umm al-Qura Isha = Maghrib + 120 min during Ramadan (TODO in `AdhanPrayerTimesRepository`).
9. **Icons**: Material icons are placeholders for the custom thin-stroke NOOR icon set.
10. Optional Firebase (Auth/Sync) — keep worship data local by default.
