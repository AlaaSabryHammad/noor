import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'نور'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navQuran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get navQuran;

  /// No description provided for @navPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة'**
  String get navPrayer;

  /// No description provided for @navAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get navAdhkar;

  /// No description provided for @navExplore.
  ///
  /// In ar, this message translates to:
  /// **'استكشف'**
  String get navExplore;

  /// No description provided for @greetingMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get greetingMorning;

  /// No description provided for @greetingEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get greetingEvening;

  /// No description provided for @greetingFriday.
  ///
  /// In ar, this message translates to:
  /// **'جمعة مباركة'**
  String get greetingFriday;

  /// No description provided for @nextPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get nextPrayer;

  /// No description provided for @remaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍ'**
  String get remaining;

  /// No description provided for @duhaTime.
  ///
  /// In ar, this message translates to:
  /// **'وقت الضحى'**
  String get duhaTime;

  /// No description provided for @timeOf.
  ///
  /// In ar, this message translates to:
  /// **'وقت {prayer}'**
  String timeOf(String prayer);

  /// No description provided for @fridaySunnahTitle.
  ///
  /// In ar, this message translates to:
  /// **'من سنن يوم الجمعة'**
  String get fridaySunnahTitle;

  /// No description provided for @fridaySunnahBody.
  ///
  /// In ar, this message translates to:
  /// **'قراءة سورة الكهف، والإكثار من الصلاة على النبي ﷺ'**
  String get fridaySunnahBody;

  /// No description provided for @readKahf.
  ///
  /// In ar, this message translates to:
  /// **'اقرأ الكهف'**
  String get readKahf;

  /// No description provided for @continueReading.
  ///
  /// In ar, this message translates to:
  /// **'تابع القراءة'**
  String get continueReading;

  /// No description provided for @khatma.
  ///
  /// In ar, this message translates to:
  /// **'الختمة'**
  String get khatma;

  /// No description provided for @resume.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get resume;

  /// No description provided for @quickAccess.
  ///
  /// In ar, this message translates to:
  /// **'وصول سريع'**
  String get quickAccess;

  /// No description provided for @morningAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'أذكار الصباح'**
  String get morningAdhkar;

  /// No description provided for @continueAction.
  ///
  /// In ar, this message translates to:
  /// **'أكمل'**
  String get continueAction;

  /// No description provided for @adhkarProgress.
  ///
  /// In ar, this message translates to:
  /// **'{done} من {total} أذكار'**
  String adhkarProgress(String done, String total);

  /// No description provided for @dailyLight.
  ///
  /// In ar, this message translates to:
  /// **'نور اليوم'**
  String get dailyLight;

  /// No description provided for @tabAyah.
  ///
  /// In ar, this message translates to:
  /// **'آية'**
  String get tabAyah;

  /// No description provided for @tabHadith.
  ///
  /// In ar, this message translates to:
  /// **'حديث'**
  String get tabHadith;

  /// No description provided for @tabDua.
  ///
  /// In ar, this message translates to:
  /// **'دعاء'**
  String get tabDua;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get share;

  /// No description provided for @copied.
  ///
  /// In ar, this message translates to:
  /// **'نُسخ مع المصدر'**
  String get copied;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف إلى المحفوظات'**
  String get saved;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get back;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @quranTitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن الكريم'**
  String get quranTitle;

  /// No description provided for @searchQuran.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن سورة أو آية أو كلمة'**
  String get searchQuran;

  /// No description provided for @segSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get segSurahs;

  /// No description provided for @segJuz.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get segJuz;

  /// No description provided for @segSaved.
  ///
  /// In ar, this message translates to:
  /// **'المحفوظات'**
  String get segSaved;

  /// No description provided for @meccan.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get medinan;

  /// No description provided for @ayahCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String ayahCount(String count);

  /// No description provided for @juzN.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {n}'**
  String juzN(String n);

  /// No description provided for @pageN.
  ///
  /// In ar, this message translates to:
  /// **'ص {n}'**
  String pageN(String n);

  /// No description provided for @mushafMode.
  ///
  /// In ar, this message translates to:
  /// **'مصحف'**
  String get mushafMode;

  /// No description provided for @translationMode.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة المعاني'**
  String get translationMode;

  /// No description provided for @tapAyahHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على أي آية لعرض التفسير والخيارات'**
  String get tapAyahHint;

  /// No description provided for @translationSource.
  ///
  /// In ar, this message translates to:
  /// **'ترجمة المعاني: Saheeh International — طبقة مستقلة لا تغيّر النص القرآني'**
  String get translationSource;

  /// No description provided for @tafsir.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get tafsir;

  /// No description provided for @tafsirPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'[يُعرض هنا نص التفسير المختار حرفيًا من مصدره المعتمد]'**
  String get tafsirPlaceholder;

  /// No description provided for @listen.
  ///
  /// In ar, this message translates to:
  /// **'استماع'**
  String get listen;

  /// No description provided for @play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get pause;

  /// No description provided for @ayahOf.
  ///
  /// In ar, this message translates to:
  /// **'الآية {n} من {total}'**
  String ayahOf(String n, String total);

  /// No description provided for @notInSample.
  ///
  /// In ar, this message translates to:
  /// **'عيّنة البيانات تحتوي سورة الفاتحة فقط — استورد المصحف الكامل'**
  String get notInSample;

  /// No description provided for @prayerTitle.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get prayerTitle;

  /// No description provided for @fajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get dhuhr;

  /// No description provided for @jumuah.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get jumuah;

  /// No description provided for @asr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get isha;

  /// No description provided for @passed.
  ///
  /// In ar, this message translates to:
  /// **'انقضت'**
  String get passed;

  /// No description provided for @nextTag.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get nextTag;

  /// No description provided for @endOfFajr.
  ///
  /// In ar, this message translates to:
  /// **'نهاية وقت الفجر'**
  String get endOfFajr;

  /// No description provided for @alertOn.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف تنبيه {prayer}'**
  String alertOn(String prayer);

  /// No description provided for @alertOff.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل تنبيه {prayer}'**
  String alertOff(String prayer);

  /// No description provided for @qiblaDirection.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة'**
  String get qiblaDirection;

  /// No description provided for @degFromNorth.
  ///
  /// In ar, this message translates to:
  /// **'{deg}° من الشمال'**
  String degFromNorth(String deg);

  /// No description provided for @calcMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get calcMethod;

  /// No description provided for @ummAlQura.
  ///
  /// In ar, this message translates to:
  /// **'تقويم أم القرى'**
  String get ummAlQura;

  /// No description provided for @asrStandard.
  ///
  /// In ar, this message translates to:
  /// **'العصر: الجمهور'**
  String get asrStandard;

  /// No description provided for @calcNote.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب المواقيت على جهازك دون اتصال'**
  String get calcNote;

  /// No description provided for @qiblaTitle.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qiblaTitle;

  /// No description provided for @facingQibla.
  ///
  /// In ar, this message translates to:
  /// **'أنت تتجه نحو القبلة'**
  String get facingQibla;

  /// No description provided for @turnRight.
  ///
  /// In ar, this message translates to:
  /// **'استدر يمينًا {deg}°'**
  String turnRight(String deg);

  /// No description provided for @turnLeft.
  ///
  /// In ar, this message translates to:
  /// **'استدر يسارًا {deg}°'**
  String turnLeft(String deg);

  /// No description provided for @deviceHeading.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه الجهاز'**
  String get deviceHeading;

  /// No description provided for @calibrationHint.
  ///
  /// In ar, this message translates to:
  /// **'للمعايرة: حرّك الهاتف على شكل الرقم ٨ بعيدًا عن المعادن.'**
  String get calibrationHint;

  /// No description provided for @adhkarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get adhkarTitle;

  /// No description provided for @searchAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأذكار والأدعية'**
  String get searchAdhkar;

  /// No description provided for @suggestedNow.
  ///
  /// In ar, this message translates to:
  /// **'مقترح الآن'**
  String get suggestedNow;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات'**
  String get categories;

  /// No description provided for @once.
  ///
  /// In ar, this message translates to:
  /// **'مرة واحدة'**
  String get once;

  /// No description provided for @times.
  ///
  /// In ar, this message translates to:
  /// **'{n} مرات'**
  String times(String n);

  /// No description provided for @tap.
  ///
  /// In ar, this message translates to:
  /// **'اضغط'**
  String get tap;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تمّ'**
  String get done;

  /// No description provided for @completeTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقبّل الله منك'**
  String get completeTitle;

  /// No description provided for @completeBody.
  ///
  /// In ar, this message translates to:
  /// **'أتممت أذكار الصباح لهذا اليوم'**
  String get completeBody;

  /// No description provided for @restart.
  ///
  /// In ar, this message translates to:
  /// **'البدء من جديد'**
  String get restart;

  /// No description provided for @catEvening.
  ///
  /// In ar, this message translates to:
  /// **'المساء'**
  String get catEvening;

  /// No description provided for @catSleep.
  ///
  /// In ar, this message translates to:
  /// **'النوم'**
  String get catSleep;

  /// No description provided for @catWaking.
  ///
  /// In ar, this message translates to:
  /// **'الاستيقاظ'**
  String get catWaking;

  /// No description provided for @catAfterPrayer.
  ///
  /// In ar, this message translates to:
  /// **'بعد الصلاة'**
  String get catAfterPrayer;

  /// No description provided for @catWudu.
  ///
  /// In ar, this message translates to:
  /// **'الوضوء'**
  String get catWudu;

  /// No description provided for @catMosque.
  ///
  /// In ar, this message translates to:
  /// **'المسجد'**
  String get catMosque;

  /// No description provided for @catTravel.
  ///
  /// In ar, this message translates to:
  /// **'السفر'**
  String get catTravel;

  /// No description provided for @catFood.
  ///
  /// In ar, this message translates to:
  /// **'الطعام'**
  String get catFood;

  /// No description provided for @catHome.
  ///
  /// In ar, this message translates to:
  /// **'المنزل'**
  String get catHome;

  /// No description provided for @catQuranDuas.
  ///
  /// In ar, this message translates to:
  /// **'أدعية من القرآن'**
  String get catQuranDuas;

  /// No description provided for @catSunnahDuas.
  ///
  /// In ar, this message translates to:
  /// **'أدعية من السنة'**
  String get catSunnahDuas;

  /// No description provided for @exploreTitle.
  ///
  /// In ar, this message translates to:
  /// **'استكشف'**
  String get exploreTitle;

  /// No description provided for @searchAll.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في كل الخدمات'**
  String get searchAll;

  /// No description provided for @groupWorship.
  ///
  /// In ar, this message translates to:
  /// **'العبادة اليومية'**
  String get groupWorship;

  /// No description provided for @groupKnowledge.
  ///
  /// In ar, this message translates to:
  /// **'العلم والمعرفة'**
  String get groupKnowledge;

  /// No description provided for @groupSeasons.
  ///
  /// In ar, this message translates to:
  /// **'المواسم والرحلات'**
  String get groupSeasons;

  /// No description provided for @groupCommunity.
  ///
  /// In ar, this message translates to:
  /// **'الأسرة والمجتمع'**
  String get groupCommunity;

  /// No description provided for @svcTasbeeh.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get svcTasbeeh;

  /// No description provided for @svcDuas.
  ///
  /// In ar, this message translates to:
  /// **'الأدعية'**
  String get svcDuas;

  /// No description provided for @svcNames.
  ///
  /// In ar, this message translates to:
  /// **'الأسماء الحسنى'**
  String get svcNames;

  /// No description provided for @svcPlanner.
  ///
  /// In ar, this message translates to:
  /// **'مخطط العبادات'**
  String get svcPlanner;

  /// No description provided for @svcZakat.
  ///
  /// In ar, this message translates to:
  /// **'الزكاة'**
  String get svcZakat;

  /// No description provided for @svcAudio.
  ///
  /// In ar, this message translates to:
  /// **'الصوتيات'**
  String get svcAudio;

  /// No description provided for @svcHadith.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الحديث'**
  String get svcHadith;

  /// No description provided for @svcSeerah.
  ///
  /// In ar, this message translates to:
  /// **'السيرة النبوية'**
  String get svcSeerah;

  /// No description provided for @svcAcademy.
  ///
  /// In ar, this message translates to:
  /// **'الأكاديمية'**
  String get svcAcademy;

  /// No description provided for @svcStories.
  ///
  /// In ar, this message translates to:
  /// **'قصص الأنبياء'**
  String get svcStories;

  /// No description provided for @svcBooks.
  ///
  /// In ar, this message translates to:
  /// **'الكتب'**
  String get svcBooks;

  /// No description provided for @svcLibrary.
  ///
  /// In ar, this message translates to:
  /// **'المكتبة'**
  String get svcLibrary;

  /// No description provided for @svcAsk.
  ///
  /// In ar, this message translates to:
  /// **'اسأل وتعلّم'**
  String get svcAsk;

  /// No description provided for @svcCalendar.
  ///
  /// In ar, this message translates to:
  /// **'التقويم الهجري'**
  String get svcCalendar;

  /// No description provided for @svcRamadan.
  ///
  /// In ar, this message translates to:
  /// **'رمضان'**
  String get svcRamadan;

  /// No description provided for @svcHajj.
  ///
  /// In ar, this message translates to:
  /// **'الحج والعمرة'**
  String get svcHajj;

  /// No description provided for @svcKids.
  ///
  /// In ar, this message translates to:
  /// **'ركن الأطفال'**
  String get svcKids;

  /// No description provided for @svcMosques.
  ///
  /// In ar, this message translates to:
  /// **'المساجد القريبة'**
  String get svcMosques;

  /// No description provided for @svcQibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get svcQibla;

  /// No description provided for @comingSoonTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيد التطوير'**
  String get comingSoonTitle;

  /// No description provided for @comingSoonBody.
  ///
  /// In ar, this message translates to:
  /// **'تصميم هذه الشاشة جاهز على لوحة التصميم، وسيُبنى في مرحلة لاحقة.'**
  String get comingSoonBody;

  /// No description provided for @tasbeehTitle.
  ///
  /// In ar, this message translates to:
  /// **'المسبحة'**
  String get tasbeehTitle;

  /// No description provided for @tapToCount.
  ///
  /// In ar, this message translates to:
  /// **'سبّح'**
  String get tapToCount;

  /// No description provided for @ofTarget.
  ///
  /// In ar, this message translates to:
  /// **'من {n}'**
  String ofTarget(String n);

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @allTime.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get allTime;

  /// No description provided for @reset.
  ///
  /// In ar, this message translates to:
  /// **'تصفير'**
  String get reset;

  /// No description provided for @cycleComplete.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الدورة — أحسن الله إليك'**
  String get cycleComplete;

  /// No description provided for @target.
  ///
  /// In ar, this message translates to:
  /// **'الهدف'**
  String get target;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي'**
  String get themeSystem;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In ar, this message translates to:
  /// **'أم القرى'**
  String get methodUmmAlQura;

  /// No description provided for @methodMwl.
  ///
  /// In ar, this message translates to:
  /// **'رابطة العالم الإسلامي'**
  String get methodMwl;

  /// No description provided for @methodEgyptian.
  ///
  /// In ar, this message translates to:
  /// **'الهيئة المصرية العامة للمساحة'**
  String get methodEgyptian;

  /// No description provided for @methodKarachi.
  ///
  /// In ar, this message translates to:
  /// **'جامعة العلوم الإسلامية بكراتشي'**
  String get methodKarachi;

  /// No description provided for @methodDubai.
  ///
  /// In ar, this message translates to:
  /// **'منطقة الخليج (دبي)'**
  String get methodDubai;

  /// No description provided for @methodKuwait.
  ///
  /// In ar, this message translates to:
  /// **'الكويت'**
  String get methodKuwait;

  /// No description provided for @methodQatar.
  ///
  /// In ar, this message translates to:
  /// **'قطر'**
  String get methodQatar;

  /// No description provided for @methodTurkey.
  ///
  /// In ar, this message translates to:
  /// **'رئاسة الشؤون الدينية التركية'**
  String get methodTurkey;

  /// No description provided for @methodSingapore.
  ///
  /// In ar, this message translates to:
  /// **'سنغافورة'**
  String get methodSingapore;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In ar, this message translates to:
  /// **'أمريكا الشمالية (ISNA)'**
  String get methodNorthAmerica;

  /// No description provided for @methodMoonSighting.
  ///
  /// In ar, this message translates to:
  /// **'لجنة رؤية الهلال'**
  String get methodMoonSighting;

  /// No description provided for @methodAuto.
  ///
  /// In ar, this message translates to:
  /// **'تلقائي حسب الموقع'**
  String get methodAuto;

  /// No description provided for @methodAutoUsing.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمة الآن: {method}'**
  String methodAutoUsing(String method);

  /// No description provided for @asrHanafi.
  ///
  /// In ar, this message translates to:
  /// **'العصر: الحنفي'**
  String get asrHanafi;

  /// No description provided for @calcSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'حساب المواقيت'**
  String get calcSheetTitle;

  /// No description provided for @asrRuleTitle.
  ///
  /// In ar, this message translates to:
  /// **'وقت العصر'**
  String get asrRuleTitle;

  /// No description provided for @asrRuleStandard.
  ///
  /// In ar, this message translates to:
  /// **'الجمهور (الشافعي والمالكي والحنبلي)'**
  String get asrRuleStandard;

  /// No description provided for @asrRuleHanafi.
  ///
  /// In ar, this message translates to:
  /// **'الحنفي'**
  String get asrRuleHanafi;

  /// No description provided for @calcSheetNote.
  ///
  /// In ar, this message translates to:
  /// **'قد تختلف المواقيت دقيقة أو دقيقتين عن التقويم الرسمي في بلدك. اختر الطريقة التي تعتمدها الجهة الدينية المحلية.'**
  String get calcSheetNote;

  /// No description provided for @adhanNotifTitle.
  ///
  /// In ar, this message translates to:
  /// **'حان وقت {prayer}'**
  String adhanNotifTitle(String prayer);

  /// No description provided for @notifPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات غير مسموحة. فعّلها من إعدادات الجهاز لتصلك إشعارات الأذان.'**
  String get notifPermissionDenied;

  /// No description provided for @changeLocation.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الموقع'**
  String get changeLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدام موقعي الحالي'**
  String get useMyLocation;

  /// No description provided for @searchCity.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مدينة'**
  String get searchCity;

  /// No description provided for @locServiceOff.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع متوقفة. فعّلها من إعدادات الجهاز أو اختر مدينة.'**
  String get locServiceOff;

  /// No description provided for @locDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالوصول إلى الموقع. يمكنك اختيار مدينة يدويًا.'**
  String get locDenied;

  /// No description provided for @locDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'الإذن مرفوض نهائيًا. فعّله من إعدادات التطبيق أو اختر مدينة.'**
  String get locDeniedForever;

  /// No description provided for @locUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك. حاول مجددًا أو اختر مدينة.'**
  String get locUnavailable;

  /// No description provided for @locationUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الموقع'**
  String get locationUpdated;

  /// No description provided for @locationCitiesNote.
  ///
  /// In ar, this message translates to:
  /// **'المدن المعروضة هي التي لا تطبّق التوقيت الصيفي. لأي مكان آخر استخدم موقعك الحالي.'**
  String get locationCitiesNote;

  /// No description provided for @hijriAdjust.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التاريخ الهجري (بالأيام)'**
  String get hijriAdjust;

  /// No description provided for @settingsNote.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ نور بالوضع الفاتح عند أول تشغيل. «تلقائي» يتبع إعداد الجهاز.'**
  String get settingsNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
