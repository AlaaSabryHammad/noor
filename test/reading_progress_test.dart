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

  test('khatma only moves forward and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final ctrl = c.read(readingProgressProvider.notifier);
    ctrl.markRead(2, 100, page: 30);
    ctrl.markRead(1, 3, page: 1);
    expect(c.read(readingProgressProvider).pagesRead, 30);
    expect(c.read(readingProgressProvider).surah, 1);
    expect(prefs.getInt('quran.pagesRead'), 30);
  });
}
