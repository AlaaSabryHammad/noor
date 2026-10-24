# NOOR | نور

Islamic companion app for Android and iOS, built with Flutter. Arabic-first (RTL) with English (LTR), a light theme by default and an independently designed dark theme. Most features work fully offline.

تطبيق إسلامي: القرآن الكريم، مواقيت الصلاة، الأذكار، الحديث والكتب، التقويم الهجري، ورمضان والحج — عربي أولًا وإنجليزي، ويعمل في معظمه دون اتصال.

## Features

| Area | What it does |
|---|---|
| **Quran** | Full Uthmani text (Tanzil) with Saheeh International translation. Lazy mushaf reader, jump to any ayah (`2:255`), resume where you stopped, exact mushaf pages, page-based khatma tracker, offline full-text search that ignores diacritics. |
| **Recitation** | Ayah-by-ayah streaming (everyayah.com), 8 reciters, previous/next, speed 0.75–1.5×, repeat ayah, highlight follows the reciter. |
| **Prayer times** | On-device calculation with 11 methods (automatic by region, or your choice) and Shafi‘i/Hanafi Asr, Umm al-Qura Ramadan rule, 29 offline cities or GPS, scheduled adhan notifications. |
| **Qibla** | Real compass with smoothing, calibration warning and an alignment haptic; preview slider only when the device has no sensor. |
| **Adhkar & duas** | The complete Hisn al-Muslim (132 chapters, 267 adhkar, searchable), 12 curated categories with sources, 59 Quranic supplications taken verbatim from the dataset, per-day counters. |
| **Books** | Forty Hadith of an-Nawawi, Forty Qudsi and Dehlawi (offline); Bukhari, Muslim, Abu Dawud, Tirmidhi, Nasa’i, Ibn Majah and Malik fetched per chapter and cached. |
| **Learn** | 99 Names, 60+ hadith, a 33-event seerah timeline, 25 stories from the Quran, 15 step-by-step lessons (wudu, ghusl, prayer, adhan, Friday and Eid, janazah, fasting, zakat, tajweed, …), 40+ FAQ, kids’ quiz with rotating rounds. A rotating daily ayah, hadith and dua on the home screen. |
| **Tools** | Hijri calendar with occasions, Ramadan tracker, Hajj & Umrah guide, zakat calculator, daily worship planner with streak, tasbeeh, saved items library. |
| **Accounts (optional)** | Firebase Auth: e-mail/password, Google, guest. The app is fully usable without signing in. |

## Run

```bash
flutter pub get
flutter run            # Android / iOS
flutter test           # unit, widget, layout-stress and golden tests
flutter test test/screens --update-goldens   # re-render the screenshots in test/screens/shots
```

Flutter 3.47 / Dart 3.13. `flutter gen-l10n` runs automatically on build.

## Project layout

```
lib/
  app/          router, bottom-navigation shell, MaterialApp
  core/         theme tokens, shared widgets, formatting, providers
  features/     quran · prayer · adhkar · books · services (calendar, zakat, …) ·
                library · settings · auth · home · explore · tasbeeh
  l10n/         ARB files (Arabic template + English)
assets/
  data/         quran/ (index + one file per surah), books/, adhkar, names, … (JSON)
  fonts/        Amiri, Amiri Quran, IBM Plex Sans Arabic, Plus Jakarta Sans
tool/           Python scripts that build assets/data and the app icon
test/           unit + widget + layout stress + golden tests
```

State is Riverpod; routing is go_router. Everything that touches the outside world (location, compass, notifications, audio, HTTP, accounts) sits behind a small interface so tests substitute fakes.

## Content and licences

- Quran text: [Tanzil Project](https://tanzil.net) Uthmani v1.1 — **CC BY 3.0**; keep the attribution (shown in *Settings → About*). Shown unmodified except that the basmala is displayed above ayah 1 instead of inside it.
- Translation: Saheeh International via Tanzil.
- Hadith text: [fawazahmed0/hadith-api](https://github.com/fawazahmed0/hadith-api) — The Unlicense.
- Hisn al-Muslim: [YousefAsalya/Islamic-Pro-azkar-API](https://github.com/YousefAsalya/Islamic-Pro-azkar-API) — MIT (text by Sa‘id al-Qahtani).
- Recitation: streamed from everyayah.com.
- Fonts: SIL Open Font License.
- Adhkar, duas, names, seerah, stories, FAQ and lessons were written for this app with their sources noted; **have them reviewed by qualified scholars before a public release.**

Rebuild the data with the scripts in `tool/` (see `tool/README.md`).

## Firebase (accounts)

Linked to the Firebase project `noor-app-alaa-4829` (Email/Password, Google and Anonymous sign-in enabled). Setup, how to re-create it for a fork, and the pre-release checklist are in [docs/FIREBASE.md](docs/FIREBASE.md). If Firebase cannot start the app simply runs without accounts.
