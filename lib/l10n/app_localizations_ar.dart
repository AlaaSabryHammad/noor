// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نور';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navPrayer => 'الصلاة';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navExplore => 'استكشف';

  @override
  String get greetingMorning => 'صباح الخير';

  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get greetingFriday => 'جمعة مباركة';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get remaining => 'متبقٍ';

  @override
  String get duhaTime => 'وقت الضحى';

  @override
  String timeOf(String prayer) {
    return 'وقت $prayer';
  }

  @override
  String get fridaySunnahTitle => 'من سنن يوم الجمعة';

  @override
  String get fridaySunnahBody =>
      'قراءة سورة الكهف، والإكثار من الصلاة على النبي ﷺ';

  @override
  String get readKahf => 'اقرأ الكهف';

  @override
  String get continueReading => 'تابع القراءة';

  @override
  String get khatma => 'الختمة';

  @override
  String get resume => 'متابعة';

  @override
  String get quickAccess => 'وصول سريع';

  @override
  String get morningAdhkar => 'أذكار الصباح';

  @override
  String get continueAction => 'أكمل';

  @override
  String adhkarProgress(String done, String total) {
    return '$done من $total أذكار';
  }

  @override
  String get dailyLight => 'نور اليوم';

  @override
  String get tabAyah => 'آية';

  @override
  String get tabHadith => 'حديث';

  @override
  String get tabDua => 'دعاء';

  @override
  String get copy => 'نسخ';

  @override
  String get save => 'حفظ';

  @override
  String get share => 'مشاركة';

  @override
  String get copied => 'نُسخ مع المصدر';

  @override
  String get saved => 'أُضيف إلى المحفوظات';

  @override
  String get back => 'رجوع';

  @override
  String get close => 'إغلاق';

  @override
  String get quranTitle => 'القرآن الكريم';

  @override
  String get searchQuran => 'ابحث عن سورة أو آية أو كلمة';

  @override
  String get segSurahs => 'السور';

  @override
  String get segJuz => 'الأجزاء';

  @override
  String get segSaved => 'المحفوظات';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String ayahCount(String count) {
    return '$count آية';
  }

  @override
  String juzN(String n) {
    return 'الجزء $n';
  }

  @override
  String pageN(String n) {
    return 'ص $n';
  }

  @override
  String get mushafMode => 'مصحف';

  @override
  String get translationMode => 'ترجمة المعاني';

  @override
  String get tapAyahHint => 'اضغط على أي آية لعرض التفسير والخيارات';

  @override
  String get translationSource =>
      'ترجمة المعاني: Saheeh International — طبقة مستقلة لا تغيّر النص القرآني';

  @override
  String get tafsir => 'التفسير';

  @override
  String get tafsirPlaceholder =>
      '[يُعرض هنا نص التفسير المختار حرفيًا من مصدره المعتمد]';

  @override
  String get listen => 'استماع';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String ayahOf(String n, String total) {
    return 'الآية $n من $total';
  }

  @override
  String get notInSample =>
      'عيّنة البيانات تحتوي سورة الفاتحة فقط — استورد المصحف الكامل';

  @override
  String get prayerTitle => 'مواقيت الصلاة';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get jumuah => 'الجمعة';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get passed => 'انقضت';

  @override
  String get nextTag => 'القادمة';

  @override
  String get endOfFajr => 'نهاية وقت الفجر';

  @override
  String alertOn(String prayer) {
    return 'إيقاف تنبيه $prayer';
  }

  @override
  String alertOff(String prayer) {
    return 'تفعيل تنبيه $prayer';
  }

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String degFromNorth(String deg) {
    return '$deg° من الشمال';
  }

  @override
  String get calcMethod => 'طريقة الحساب';

  @override
  String get ummAlQura => 'تقويم أم القرى';

  @override
  String get asrStandard => 'العصر: الجمهور';

  @override
  String get calcNote => 'تُحسب المواقيت على جهازك دون اتصال';

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String get facingQibla => 'أنت تتجه نحو القبلة';

  @override
  String turnRight(String deg) {
    return 'استدر يمينًا $deg°';
  }

  @override
  String turnLeft(String deg) {
    return 'استدر يسارًا $deg°';
  }

  @override
  String get deviceHeading => 'اتجاه الجهاز';

  @override
  String get calibrationHint =>
      'للمعايرة: حرّك الهاتف على شكل الرقم ٨ بعيدًا عن المعادن.';

  @override
  String get adhkarTitle => 'الأذكار';

  @override
  String get searchAdhkar => 'ابحث في الأذكار والأدعية';

  @override
  String get suggestedNow => 'مقترح الآن';

  @override
  String get categories => 'التصنيفات';

  @override
  String get once => 'مرة واحدة';

  @override
  String times(String n) {
    return '$n مرات';
  }

  @override
  String get tap => 'اضغط';

  @override
  String get done => 'تمّ';

  @override
  String get completeTitle => 'تقبّل الله منك';

  @override
  String get completeBody => 'أتممت أذكار الصباح لهذا اليوم';

  @override
  String get restart => 'البدء من جديد';

  @override
  String get catEvening => 'المساء';

  @override
  String get catSleep => 'النوم';

  @override
  String get catWaking => 'الاستيقاظ';

  @override
  String get catAfterPrayer => 'بعد الصلاة';

  @override
  String get catWudu => 'الوضوء';

  @override
  String get catMosque => 'المسجد';

  @override
  String get catTravel => 'السفر';

  @override
  String get catFood => 'الطعام';

  @override
  String get catHome => 'المنزل';

  @override
  String get catQuranDuas => 'أدعية من القرآن';

  @override
  String get catSunnahDuas => 'أدعية من السنة';

  @override
  String get exploreTitle => 'استكشف';

  @override
  String get searchAll => 'ابحث في كل الخدمات';

  @override
  String get groupWorship => 'العبادة اليومية';

  @override
  String get groupKnowledge => 'العلم والمعرفة';

  @override
  String get groupSeasons => 'المواسم والرحلات';

  @override
  String get groupCommunity => 'الأسرة والمجتمع';

  @override
  String get svcTasbeeh => 'المسبحة';

  @override
  String get svcDuas => 'الأدعية';

  @override
  String get svcNames => 'الأسماء الحسنى';

  @override
  String get svcPlanner => 'مخطط العبادات';

  @override
  String get svcZakat => 'الزكاة';

  @override
  String get svcAudio => 'الصوتيات';

  @override
  String get svcHadith => 'مكتبة الحديث';

  @override
  String get svcSeerah => 'السيرة النبوية';

  @override
  String get svcAcademy => 'الأكاديمية';

  @override
  String get svcStories => 'قصص الأنبياء';

  @override
  String get svcBooks => 'الكتب';

  @override
  String get svcLibrary => 'المكتبة';

  @override
  String get svcAsk => 'اسأل وتعلّم';

  @override
  String get svcCalendar => 'التقويم الهجري';

  @override
  String get svcRamadan => 'رمضان';

  @override
  String get svcHajj => 'الحج والعمرة';

  @override
  String get svcKids => 'ركن الأطفال';

  @override
  String get svcMosques => 'المساجد القريبة';

  @override
  String get svcQibla => 'القبلة';

  @override
  String get comingSoonTitle => 'قيد التطوير';

  @override
  String get comingSoonBody =>
      'تصميم هذه الشاشة جاهز على لوحة التصميم، وسيُبنى في مرحلة لاحقة.';

  @override
  String get tasbeehTitle => 'المسبحة';

  @override
  String get tapToCount => 'سبّح';

  @override
  String ofTarget(String n) {
    return 'من $n';
  }

  @override
  String get today => 'اليوم';

  @override
  String get allTime => 'الإجمالي';

  @override
  String get reset => 'تصفير';

  @override
  String get cycleComplete => 'اكتملت الدورة — أحسن الله إليك';

  @override
  String get target => 'الهدف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get appearance => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get methodUmmAlQura => 'أم القرى';

  @override
  String get methodMwl => 'رابطة العالم الإسلامي';

  @override
  String get methodEgyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get methodKarachi => 'جامعة العلوم الإسلامية بكراتشي';

  @override
  String get methodDubai => 'منطقة الخليج (دبي)';

  @override
  String get methodKuwait => 'الكويت';

  @override
  String get methodQatar => 'قطر';

  @override
  String get methodTurkey => 'رئاسة الشؤون الدينية التركية';

  @override
  String get methodSingapore => 'سنغافورة';

  @override
  String get methodNorthAmerica => 'أمريكا الشمالية (ISNA)';

  @override
  String get methodMoonSighting => 'لجنة رؤية الهلال';

  @override
  String get methodAuto => 'تلقائي حسب الموقع';

  @override
  String methodAutoUsing(String method) {
    return 'المستخدمة الآن: $method';
  }

  @override
  String get asrHanafi => 'العصر: الحنفي';

  @override
  String get calcSheetTitle => 'حساب المواقيت';

  @override
  String get asrRuleTitle => 'وقت العصر';

  @override
  String get asrRuleStandard => 'الجمهور (الشافعي والمالكي والحنبلي)';

  @override
  String get asrRuleHanafi => 'الحنفي';

  @override
  String get calcSheetNote =>
      'قد تختلف المواقيت دقيقة أو دقيقتين عن التقويم الرسمي في بلدك. اختر الطريقة التي تعتمدها الجهة الدينية المحلية.';

  @override
  String adhanNotifTitle(String prayer) {
    return 'حان وقت $prayer';
  }

  @override
  String get notifPermissionDenied =>
      'التنبيهات غير مسموحة. فعّلها من إعدادات الجهاز لتصلك إشعارات الأذان.';

  @override
  String get changeLocation => 'تغيير الموقع';

  @override
  String get useMyLocation => 'استخدام موقعي الحالي';

  @override
  String get searchCity => 'ابحث عن مدينة';

  @override
  String get locServiceOff =>
      'خدمة الموقع متوقفة. فعّلها من إعدادات الجهاز أو اختر مدينة.';

  @override
  String get locDenied =>
      'لم يُسمح بالوصول إلى الموقع. يمكنك اختيار مدينة يدويًا.';

  @override
  String get locDeniedForever =>
      'الإذن مرفوض نهائيًا. فعّله من إعدادات التطبيق أو اختر مدينة.';

  @override
  String get locUnavailable => 'تعذّر تحديد موقعك. حاول مجددًا أو اختر مدينة.';

  @override
  String get locationUpdated => 'تم تحديث الموقع';

  @override
  String get locationCitiesNote =>
      'المدن المعروضة هي التي لا تطبّق التوقيت الصيفي. لأي مكان آخر استخدم موقعك الحالي.';

  @override
  String get hijriAdjust => 'تعديل التاريخ الهجري (بالأيام)';

  @override
  String get settingsNote =>
      'يبدأ نور بالوضع الفاتح عند أول تشغيل. «تلقائي» يتبع إعداد الجهاز.';
}
