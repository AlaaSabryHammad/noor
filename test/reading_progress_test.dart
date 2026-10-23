import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/core/providers.dart';
import 'package:noor/features/quran/quran_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const index = QuranIndex(
    surahs: [
      Surah(number: 1, nameAr: 'الفاتحة', nameEn: 'Al-Fatihah', revelation: Revelation.meccan, ayahCount: 7, startPage: 1),
      Surah(number: 2, nameAr: 'البقرة', nameEn: 'Al-Baqarah', revelation: Revelation.medinan, ayahCount: 286, startPage: 2),
    ],
    juz: [],
  );

  test('estimatePage stays within the surah page range', () {
    expect(index.estimatePage(1, 1), 1);
    expect(index.estimatePage(2, 286), 604);
    expect(index.estimatePage(99, 1), 1);
  });

  test('khatma counts distinct pages read, never shrinks, and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final ctrl = c.read(readingProgressProvider.notifier);
    ctrl.markRead(2, 100, pages: [30, 31, 32]);
    ctrl.markRead(1, 3, pages: [1, 31]); // page 31 again: still counted once
    final p = c.read(readingProgressProvider);
    expect(p.pagesRead, 4);
    expect(p.surah, 1);
    expect(p.khatma, closeTo(4 / 604, 1e-9));
    expect(prefs.getString('quran.readPages'), '1,30,31,32');

    // Jumping to the last surah no longer fakes a finished khatma.
    ctrl.markRead(114, 1, pages: [604]);
    expect(c.read(readingProgressProvider).pagesRead, 5);

    final again = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(again.dispose);
    expect(again.read(readingProgressProvider).readPages, {1, 30, 31, 32, 604});
  });

  test('starting a new khatma clears pages but keeps the bookmark', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final ctrl = c.read(readingProgressProvider.notifier);
    ctrl.markRead(18, 10, pages: [293, 294]);
    ctrl.resetKhatma();
    final p = c.read(readingProgressProvider);
    expect((p.surah, p.ayah, p.pagesRead), (18, 10, 0));
  });

  test('corrupt saved pages are ignored', () async {
    SharedPreferences.setMockInitialValues({'quran.readPages': '5,x,9999,-3,7'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    expect(c.read(readingProgressProvider).readPages, {5, 7});
  });
}
