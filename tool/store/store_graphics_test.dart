// Generates the Google Play listing graphics into fastlane/metadata/android/<locale>/images:
//
//   flutter test tool/store/store_graphics_test.dart
//
// It is not part of `flutter test` (that only scans test/). Each phone screenshot is the real app rendered at
// 390×746 (3×), set in a phone frame under a caption, at Play's 1080×1920; tablet shots are the app itself at
// 2560×1600; the feature graphic is 1024×500; the icon is the launcher icon at 512×512.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:noor/app/app.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/core/theme/noor_theme.dart';
import 'package:noor/core/theme/noor_tokens.dart';
import 'package:noor/features/audio/audio_catalog.dart';
import 'package:noor/features/prayer/alert_sync.dart';
import 'package:noor/features/prayer/compass.dart';
import 'package:noor/features/prayer/data/notification_scheduler.dart';
import 'package:noor/features/prayer/domain/alert_models.dart';
import 'package:noor/features/prayer/domain/alert_planner.dart';
import 'package:noor/features/prayer/domain/prayer_cities.dart';
import 'package:noor/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test/test_clock.dart';

/// A phone with a compass pointing a little off the Qibla (about 244° in Riyadh), so the screenshot shows the
/// live compass rather than the "no sensor" fallback.
class _FakeCompass implements CompassSource {
  @override
  Stream<CompassReading>? get readings => Stream.value(const CompassReading(231, accuracy: 6));
}

class _NoopScheduler implements NotificationScheduler {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> replaceAll(List<PlannedAlert> alerts) async {}
}

/// Makes the alert card of the Prayer screen show as it does on a healthy phone.
class _HealthyAlerts implements AlertDiagnostics {
  @override
  Future<AlertHealth> health() async => const AlertHealth(pending: 30);
  @override
  Future<bool> scheduleTest({required AdhanSound sound, required String title, required String body, Duration after = const Duration(seconds: 10)}) async => true;
  @override
  Future<void> openSettings(AlertSettingsPage page) async {}
}

Future<void> _loadFonts() async {
  const fams = {
    'AmiriQuran': ['AmiriQuran-Regular'],
    'Amiri': ['Amiri-Regular', 'Amiri-Bold'],
    'IBMPlexSansArabic': ['IBMPlexSansArabic-Regular', 'IBMPlexSansArabic-Medium', 'IBMPlexSansArabic-SemiBold', 'IBMPlexSansArabic-Bold'],
    'PlusJakartaSans': ['PlusJakartaSans-Regular', 'PlusJakartaSans-Medium', 'PlusJakartaSans-SemiBold', 'PlusJakartaSans-Bold'],
  };
  for (final e in fams.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(rootBundle.load('assets/fonts/$f.ttf'));
    }
    await loader.load();
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

/// One phone screenshot: the route to show, its look, and the caption in both languages.
typedef Shot = ({String route, String theme, double scroll, (String, String) titleAr, (String, String) titleEn});

const phoneShots = <Shot>[
  (route: '/home', theme: 'light', scroll: 0, titleAr: ('مواقيت الصلاة بدقة', 'تحديد تلقائي للموقع وإحدى عشرة طريقة حساب'), titleEn: ('Accurate prayer times', 'Automatic location and 11 calculation methods')),
  (route: '/prayer', theme: 'light', scroll: 380, titleAr: ('أذان حقيقي في كل صلاة', 'في وقته، حتى والهاتف على الصامت'), titleEn: ('A real adhan at every prayer', 'On time, even when the phone is silent')),
  (route: '/quran/reader/2?ayah=255', theme: 'dark', scroll: 0, titleAr: ('المصحف الكامل', 'الرسم العثماني والترجمة والبحث والتلاوة'), titleEn: ('The complete Quran', 'Uthmani script, translation, search and recitation')),
  (route: '/audio', theme: 'light', scroll: 0, titleAr: ('تلاوات وإذاعات وتفسير', 'استمع في الخلفية ومن شاشة القفل'), titleEn: ('Recitations, radio and tafsir', 'Listen in the background and from the lock screen')),
  (route: '/hisn', theme: 'light', scroll: 0, titleAr: ('حصن المسلم كاملًا', '١٣٢ بابًا من الأذكار والأدعية'), titleEn: ('The full Hisn al-Muslim', '132 chapters of adhkar and supplications')),
  (route: '/qibla', theme: 'dark', scroll: 0, titleAr: ('بوصلة القبلة', 'بوصلة حقيقية مع تنبيه المعايرة'), titleEn: ('Qibla compass', 'A real compass with calibration help')),
  (route: '/books', theme: 'light', scroll: 0, titleAr: ('مكتبة الحديث', 'الأربعون النووية والبخاري ومسلم وغيرها'), titleEn: ('Hadith library', 'Forty Hadith, Bukhari, Muslim and more')),
  (route: '/explore', theme: 'light', scroll: 0, titleAr: ('كل ما تحتاجه في تطبيق واحد', 'التقويم الهجري ورمضان والحج والزكاة'), titleEn: ('Everything in one app', 'Hijri calendar, Ramadan, Hajj, zakat and more')),
];

const tabletShots = <(String route, String theme)>[('/home', 'light'), ('/prayer', 'light'), ('/quran/reader/2?ayah=255', 'dark'), ('/audio', 'light')];

const _locales = {'ar': 'ar', 'en': 'en-US'};
const _out = 'fastlane/metadata/android';
const _raw = 'build/store/raw';

Future<void> _savePng(WidgetTester tester, GlobalKey key, String path, {double pixelRatio = 1}) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

/// Renders the real app on [route] and saves it as a PNG.
Future<void> _renderApp(WidgetTester tester, {required String lang, required String theme, required String route, required Size size, required double ratio, required double scroll, required String path}) async {
  final riyadh = prayerCities.firstWhere((c) => c.nameEn.startsWith('Riyadh'));
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'settings.locale': lang, 'settings.theme': theme, 'prayer.location': jsonEncode(riyadh.toJson())});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  final key = GlobalKey();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationSchedulerProvider.overrideWithValue(_NoopScheduler()),
      alertDiagnosticsProvider.overrideWithValue(_HealthyAlerts()),
      compassSourceProvider.overrideWithValue(_FakeCompass()),
      nowProvider.overrideWithValue(fridayMorning),
      contentLoaderProvider.overrideWithValue((p) async => File(p).readAsStringSync()),
      audioCatalogAutoRefreshProvider.overrideWithValue(false),
    ],
    child: RepaintBoundary(key: key, child: const NoorApp()),
  ));
  await tester.pumpAndSettle();
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(route);
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(seconds: 1));
  if (scroll > 0) {
    await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll));
    await tester.pump(const Duration(seconds: 1));
  }
  await _savePng(tester, key, path, pixelRatio: 1);
  // Leave the tree before the view is reset, so the next shot starts clean.
  await tester.pumpWidget(const SizedBox());
}

Future<ui.Image> _decode(WidgetTester tester, String path) async {
  final bytes = File(path).readAsBytesSync();
  final image = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    return (await codec.getNextFrame()).image;
  });
  return image!;
}

/// The wrapper every composed graphic sits in: theme, fonts and the language's text direction.
Widget _stage(String lang, Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: NoorTheme.light(Locale(lang)),
      home: Material(color: Colors.transparent, child: child),
    );

const _bgTop = Color(0xFF0E7A66), _bgBottom = Color(0xFF053B33);

/// Faint eight-point stars over the gradient, like the app's hero surfaces.
class _StarPattern extends StatelessWidget {
  const _StarPattern({required this.size});
  final Size size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: size, painter: _StarsPainter());
}

class _StarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x14FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const step = 150.0;
    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = 0.0; x < size.width + step; x += step) {
        final c = Offset(x + ((y / step).round().isOdd ? step / 2 : 0), y);
        for (var k = 0; k < 2; k++) {
          final path = Path();
          for (var i = 0; i < 4; i++) {
            final a = math.pi / 4 + i * math.pi / 2 + k * math.pi / 4;
            final pt = Offset(c.dx + 36 * math.cos(a), c.dy + 36 * math.sin(a));
            i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
          }
          path.close();
          canvas.drawPath(path, p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

BoxDecoration get _gradient => const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bgTop, _bgBottom]));

/// A phone: the screenshot clipped to rounded corners inside a dark bezel.
Widget _phone(ui.Image shot, {required double width}) {
  final inner = width - 28;
  return Container(
    width: width,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF0B1512), borderRadius: BorderRadius.circular(76), border: Border.all(color: const Color(0xFF2A3A35), width: 3), boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 60, offset: Offset(0, 24))]),
    child: ClipRRect(borderRadius: BorderRadius.circular(62), child: SizedBox(width: inner, height: inner * shot.height / shot.width, child: RawImage(image: shot, fit: BoxFit.fill, filterQuality: FilterQuality.high))),
  );
}

void main() {
  setUpAll(_loadFonts);

  for (final entry in _locales.entries) {
    final lang = entry.key, locale = entry.value;
    final dir = '$_out/$locale/images';

    testWidgets('$locale · render the app', (tester) async {
      addTearDown(tester.view.reset);
      for (var i = 0; i < phoneShots.length; i++) {
        final s = phoneShots[i];
        await _renderApp(tester, lang: lang, theme: s.theme, route: s.route, size: const Size(390, 746), ratio: 3, scroll: s.scroll, path: '$_raw/$lang-${i + 1}.png');
      }
      for (var i = 0; i < tabletShots.length; i++) {
        final s = tabletShots[i];
        await _renderApp(tester, lang: lang, theme: s.$2, route: s.$1, size: const Size(1280, 800), ratio: 2, scroll: 0, path: '$dir/tenInchScreenshots/${i + 1}.png');
      }
    });

    testWidgets('$locale · phone screenshots', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1;
      final ar = lang == 'ar';
      for (var i = 0; i < phoneShots.length; i++) {
        final s = phoneShots[i];
        final (title, sub) = ar ? s.titleAr : s.titleEn;
        final shot = await _decode(tester, '$_raw/$lang-${i + 1}.png');
        final key = GlobalKey();
        await tester.pumpWidget(_stage(
          lang,
          RepaintBoundary(
            key: key,
            child: Directionality(
              textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              child: Container(
                width: 1080,
                height: 1920,
                decoration: _gradient,
                child: Stack(children: [
                  const Positioned.fill(child: _StarPattern(size: Size(1080, 1920))),
                  Positioned.fill(
                      child: Column(children: [
                    const SizedBox(height: 96),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 70),
                      child: Column(children: [
                        Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: ar ? 'Amiri' : 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: ar ? 92 : 66, color: Colors.white, height: 1.25)),
                        const SizedBox(height: 14),
                        Text(sub, textAlign: TextAlign.center, style: TextStyle(fontFamily: ar ? 'IBMPlexSansArabic' : 'PlusJakartaSans', fontWeight: FontWeight.w500, fontSize: ar ? 40 : 34, color: NoorTokens.onHeroAccent, height: 1.4)),
                      ]),
                    ),
                    const SizedBox(height: 48),
                    // The phone takes whatever height is left and is cropped by the bottom edge, like a phone rising from it.
                    Expanded(child: ClipRect(child: OverflowBox(alignment: Alignment.topCenter, minHeight: 0, maxHeight: 2800, child: _phone(shot, width: 830)))),
                  ])),
                ]),
              ),
            ),
          ),
        ));
        await tester.pump();
        await _savePng(tester, key, '$dir/phoneScreenshots/${i + 1}.png');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('$locale · icon and feature graphic', (tester) async {
      addTearDown(tester.view.reset);
      // Icon: the launcher artwork, square, 512 px.
      final src = File('assets/icon/noor_icon.png').readAsBytesSync();
      final iconImage = await tester.runAsync(() async => (await (await ui.instantiateImageCodec(src, targetWidth: 512, targetHeight: 512)).getNextFrame()).image);
      final iconBytes = await tester.runAsync(() async => (await iconImage!.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List());
      File('$dir/icon.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(iconBytes!);

      // Feature graphic: 1024×500.
      tester.view.physicalSize = const Size(1024, 500);
      tester.view.devicePixelRatio = 1;
      final shot = await _decode(tester, '$_raw/$lang-1.png');
      final key = GlobalKey();
      final ar = lang == 'ar';
      await tester.pumpWidget(_stage(
        lang,
        RepaintBoundary(
          key: key,
          child: Directionality(
            textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
            child: Container(
              width: 1024,
              height: 500,
              decoration: _gradient,
              child: Stack(children: [
                const Positioned.fill(child: _StarPattern(size: Size(1024, 500))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ClipRRect(borderRadius: BorderRadius.circular(26), child: Image.memory(src, width: 92, height: 92)),
                        const SizedBox(height: 18),
                        Text('نور | NOOR', style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.w700, fontSize: 70, color: Colors.white, height: 1.15)),
                        const SizedBox(height: 8),
                        Text(
                          ar ? 'القرآن · مواقيت الصلاة · الأذان · الأذكار' : 'Quran · Prayer times · Adhan · Adhkar',
                          style: TextStyle(fontFamily: ar ? 'IBMPlexSansArabic' : 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 27, color: NoorTokens.onHeroAccent, height: 1.5),
                        ),
                        Text(
                          ar ? 'تطبيق إسلامي متكامل يعمل دون إنترنت' : 'A complete Islamic app that works offline',
                          style: TextStyle(fontFamily: ar ? 'IBMPlexSansArabic' : 'PlusJakartaSans', fontSize: 22, color: const Color(0xCCFFFFFF), height: 1.5),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 24),
                    // A phone peeking in from the bottom, cropped by the banner's edge.
                    SizedBox(
                      width: 300,
                      height: 500,
                      child: OverflowBox(alignment: Alignment.topCenter, maxHeight: 900, child: Padding(padding: const EdgeInsets.only(top: 56), child: _phone(shot, width: 300))),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ));
      await tester.pump();
      await _savePng(tester, key, '$dir/featureGraphic.png');
    });
  }
}
