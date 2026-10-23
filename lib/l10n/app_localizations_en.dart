// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'NOOR';

  @override
  String get navHome => 'Home';

  @override
  String get navQuran => 'Quran';

  @override
  String get navPrayer => 'Prayer';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navExplore => 'Explore';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingFriday => 'Jumu‘ah Mubarak';

  @override
  String get nextPrayer => 'Next prayer';

  @override
  String get remaining => 'Remaining';

  @override
  String get duhaTime => 'Duha time';

  @override
  String timeOf(String prayer) {
    return '$prayer time';
  }

  @override
  String get fridaySunnahTitle => 'Friday sunnah';

  @override
  String get fridaySunnahBody =>
      'Read Surah Al-Kahf and send abundant salawat upon the Prophet ﷺ';

  @override
  String get readKahf => 'Read Al-Kahf';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get khatma => 'Khatma';

  @override
  String get resume => 'Resume';

  @override
  String get quickAccess => 'Quick access';

  @override
  String get morningAdhkar => 'Morning Adhkar';

  @override
  String get continueAction => 'Continue';

  @override
  String adhkarProgress(String done, String total) {
    return '$done of $total adhkar';
  }

  @override
  String get dailyLight => 'Daily light';

  @override
  String get tabAyah => 'Ayah';

  @override
  String get tabHadith => 'Hadith';

  @override
  String get tabDua => 'Dua';

  @override
  String get copy => 'Copy';

  @override
  String get save => 'Save';

  @override
  String get share => 'Share';

  @override
  String get copied => 'Copied with its source';

  @override
  String get saved => 'Added to Saved';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get quranTitle => 'The Holy Quran';

  @override
  String get searchQuran => 'Search surah, ayah or word';

  @override
  String get segSurahs => 'Surahs';

  @override
  String get segJuz => 'Juz';

  @override
  String get segSaved => 'Saved';

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String ayahCount(String count) {
    return '$count ayahs';
  }

  @override
  String juzN(String n) {
    return 'Juz $n';
  }

  @override
  String pageN(String n) {
    return 'p. $n';
  }

  @override
  String get mushafMode => 'Mushaf';

  @override
  String get translationMode => 'Translation';

  @override
  String get tapAyahHint => 'Tap any ayah for tafsir and options';

  @override
  String get translationSource =>
      'Translation of meanings: Saheeh International — a separate layer; the Arabic text never changes';

  @override
  String get tafsir => 'Tafsir';

  @override
  String get tafsirPlaceholder =>
      '[The selected tafsir appears here verbatim from its authorised source]';

  @override
  String get listen => 'Listen';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String ayahOf(String n, String total) {
    return 'Ayah $n of $total';
  }

  @override
  String get notInSample =>
      'The sample data includes Al-Fatihah only — import the full mushaf';

  @override
  String get prayerTitle => 'Prayer Times';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get jumuah => 'Jumu‘ah';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get passed => 'Passed';

  @override
  String get nextTag => 'Next';

  @override
  String get endOfFajr => 'End of Fajr time';

  @override
  String alertOn(String prayer) {
    return 'Turn off $prayer alert';
  }

  @override
  String alertOff(String prayer) {
    return 'Turn on $prayer alert';
  }

  @override
  String get qiblaDirection => 'Qibla direction';

  @override
  String degFromNorth(String deg) {
    return '$deg° from North';
  }

  @override
  String get calcMethod => 'Calculation';

  @override
  String get ummAlQura => 'Umm al-Qura';

  @override
  String get asrStandard => 'Asr: Standard';

  @override
  String get calcNote => 'Times are calculated on-device, offline';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get facingQibla => 'You are facing the Qibla';

  @override
  String turnRight(String deg) {
    return 'Turn right $deg°';
  }

  @override
  String turnLeft(String deg) {
    return 'Turn left $deg°';
  }

  @override
  String get deviceHeading => 'Device heading';

  @override
  String get simulateHeading =>
      'Simulated heading (until the compass sensor is wired)';

  @override
  String get calibrationHint =>
      'To calibrate, move your phone in a figure-8 away from metal.';

  @override
  String get adhkarTitle => 'Adhkar';

  @override
  String get searchAdhkar => 'Search adhkar and duas';

  @override
  String get suggestedNow => 'Suggested now';

  @override
  String get categories => 'Categories';

  @override
  String get once => 'Once';

  @override
  String times(String n) {
    return '$n times';
  }

  @override
  String get tap => 'tap';

  @override
  String get done => 'Done';

  @override
  String get completeTitle => 'May Allah accept it';

  @override
  String get completeBody => 'You completed today’s morning adhkar';

  @override
  String get restart => 'Start again';

  @override
  String get catEvening => 'Evening';

  @override
  String get catSleep => 'Sleep';

  @override
  String get catWaking => 'Waking up';

  @override
  String get catAfterPrayer => 'After prayer';

  @override
  String get catWudu => 'Wudu';

  @override
  String get catMosque => 'Mosque';

  @override
  String get catTravel => 'Travel';

  @override
  String get catFood => 'Food';

  @override
  String get catHome => 'Home';

  @override
  String get catQuranDuas => 'Quranic duas';

  @override
  String get catSunnahDuas => 'Sunnah duas';

  @override
  String get exploreTitle => 'Explore';

  @override
  String get searchAll => 'Search all services';

  @override
  String get groupWorship => 'Daily worship';

  @override
  String get groupKnowledge => 'Knowledge';

  @override
  String get groupSeasons => 'Seasons & journeys';

  @override
  String get groupCommunity => 'Family & community';

  @override
  String get svcTasbeeh => 'Tasbeeh';

  @override
  String get svcDuas => 'Duas';

  @override
  String get svcNames => '99 Names';

  @override
  String get svcPlanner => 'Planner';

  @override
  String get svcZakat => 'Zakat';

  @override
  String get svcAudio => 'Audio';

  @override
  String get svcHadith => 'Hadith';

  @override
  String get svcSeerah => 'Seerah';

  @override
  String get svcAcademy => 'Academy';

  @override
  String get svcStories => 'Prophets’ stories';

  @override
  String get svcLibrary => 'Library';

  @override
  String get svcAsk => 'Ask & learn';

  @override
  String get svcCalendar => 'Hijri calendar';

  @override
  String get svcRamadan => 'Ramadan';

  @override
  String get svcHajj => 'Hajj & Umrah';

  @override
  String get svcKids => 'Muslim Kids';

  @override
  String get svcMosques => 'Nearby mosques';

  @override
  String get svcQibla => 'Qibla';

  @override
  String get comingSoonTitle => 'In development';

  @override
  String get comingSoonBody =>
      'This screen is designed on the canvas and will be built in a later phase.';

  @override
  String get tasbeehTitle => 'Tasbeeh';

  @override
  String get tapToCount => 'Count';

  @override
  String ofTarget(String n) {
    return 'of $n';
  }

  @override
  String get today => 'Today';

  @override
  String get allTime => 'All time';

  @override
  String get reset => 'Reset';

  @override
  String get cycleComplete => 'Cycle complete — may Allah reward you';

  @override
  String get target => 'Target';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get methodUmmAlQura => 'Umm al-Qura';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodEgyptian => 'Egyptian General Authority of Survey';

  @override
  String get methodKarachi => 'Univ. of Islamic Sciences, Karachi';

  @override
  String get methodDubai => 'Gulf Region (Dubai)';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodTurkey => 'Diyanet (Türkiye)';

  @override
  String get methodSingapore => 'Singapore';

  @override
  String get methodNorthAmerica => 'North America (ISNA)';

  @override
  String get methodMoonSighting => 'Moon Sighting Committee';

  @override
  String get methodAuto => 'Automatic (by location)';

  @override
  String methodAutoUsing(String method) {
    return 'Currently using: $method';
  }

  @override
  String get asrHanafi => 'Asr: Hanafi';

  @override
  String get calcSheetTitle => 'Prayer calculation';

  @override
  String get asrRuleTitle => 'Asr time';

  @override
  String get asrRuleStandard => 'Standard (Shafi‘i, Maliki, Hanbali)';

  @override
  String get asrRuleHanafi => 'Hanafi';

  @override
  String get calcSheetNote =>
      'Times may differ by a minute or two from your country\'s official calendar. Choose the method your local religious authority uses.';

  @override
  String adhanNotifTitle(String prayer) {
    return 'It\'s time for $prayer';
  }

  @override
  String get notifPermissionDenied =>
      'Notifications are not allowed. Enable them in device settings to receive adhan alerts.';

  @override
  String get changeLocation => 'Change location';

  @override
  String get useMyLocation => 'Use my current location';

  @override
  String get searchCity => 'Search for a city';

  @override
  String get locServiceOff =>
      'Location services are off. Turn them on in device settings or pick a city.';

  @override
  String get locDenied =>
      'Location access was not allowed. You can pick a city instead.';

  @override
  String get locDeniedForever =>
      'Permission is permanently denied. Enable it in app settings or pick a city.';

  @override
  String get locUnavailable =>
      'Couldn\'t determine your location. Try again or pick a city.';

  @override
  String get locationUpdated => 'Location updated';

  @override
  String get locationCitiesNote =>
      'Listed cities are those without daylight saving. For anywhere else use your current location.';

  @override
  String get hijriAdjust => 'Hijri date adjustment (days)';

  @override
  String get settingsNote =>
      'NOOR starts in Light mode on first launch. “System” follows your device.';
}
