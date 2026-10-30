import 'package:flutter/material.dart';

import '../../core/theme/noor_theme.dart';
import '../../core/theme/noor_tokens.dart';
import '../../core/utils/noor_format.dart';
import '../../core/widgets/noor_widgets.dart';
import '../services/service_widgets.dart';

const appVersion = '0.1.0';

class _Credit {
  const _Credit(this.titleAr, this.titleEn, this.bodyAr, this.bodyEn, this.licence);
  final String titleAr, titleEn, bodyAr, bodyEn, licence;
}

/// Attribution for third-party content. Tanzil's licence requires it.
const credits = <_Credit>[
  _Credit('نص القرآن الكريم', 'Quran text', 'النص العثماني من مشروع Tanzil (الإصدار 1.1) — tanzil.net. نص محقق ومراقب باستمرار، ويُعرض دون تعديل سوى فصل البسملة عن الآية الأولى.', 'Uthmani text from the Tanzil Project (v1.1) — tanzil.net. Carefully verified and monitored; shown unmodified except that the basmala is displayed separately from ayah 1.', 'CC BY 3.0'),
  _Credit('ترجمة معاني القرآن', 'Quran translation', 'Saheeh International عبر مشروع Tanzil.', 'Saheeh International, via the Tanzil Project.', 'Tanzil terms'),
  _Credit('التلاوة', 'Recitation', 'تُبثّ ملفات التلاوة آية بآية من everyayah.com.', 'Recitation files are streamed ayah by ayah from everyayah.com.', 'everyayah.com'),
  _Credit('القرّاء والإذاعات', 'Reciters and radio', 'فهرس القرّاء وتلاوات السور كاملة والإذاعات المباشرة من واجهة mp3quran.net، وتُبثّ من خوادمهم.', 'The reciter catalogue, full-surah recitations and live radio come from the mp3quran.net API and are streamed from their servers.', 'mp3quran.net'),
  _Credit('التفاسير', 'Tafsir', 'التفسير الميسّر والمختصر والسعدي والجلالين وابن كثير والبغوي والقرطبي والطبري والوسيط، من مجموعة بيانات tafsir_api (github.com/spa5k/tafsir_api).', 'Al-Muyassar, Al-Mukhtasar, As-Sa‘di, Al-Jalalayn, Ibn Kathir, Al-Baghawi, Al-Qurtubi, At-Tabari and Al-Wasit, from the tafsir_api dataset (github.com/spa5k/tafsir_api).', 'MIT'),
  _Credit('أسماء المدن', 'City names', 'قاعدة المدن المضمّنة لتسمية موقعك دون إنترنت من مشروع GeoNames (geonames.org).', 'The bundled list of cities that names your location without internet is from the GeoNames project (geonames.org).', 'CC BY 4.0'),
  _Credit('صوت الأذان', 'Adhan recording','تسجيل «Beautiful adhan» للمستخدم Adam-synagda من ويكيميديا كومنز (commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg). نسخة iOS مقتطعة منه في ٢٨ ثانية.', 'The recording “Beautiful adhan” by Adam-synagda from Wikimedia Commons (commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg). The iOS version is cut to its first 28 seconds.', 'CC0'),
  _Credit('حصن المسلم', 'Hisn al-Muslim','أذكار «حصن المسلم» لسعيد بن علي بن وهف القحطاني، من مجموعة بيانات Islamic-Pro-azkar-API (github.com/YousefAsalya/Islamic-Pro-azkar-API).', 'The adhkar of Hisn al-Muslim by Sa‘id ibn ‘Ali ibn Wahf al-Qahtani, from the Islamic-Pro-azkar-API dataset (github.com/YousefAsalya/Islamic-Pro-azkar-API).', 'MIT'),
  _Credit('نصوص الحديث', 'Hadith text','مشروع hadith-api المفتوح (github.com/fawazahmed0/hadith-api).', 'The open hadith-api project (github.com/fawazahmed0/hadith-api).', 'The Unlicense'),
  _Credit('مواقيت الصلاة', 'Prayer times', 'تُحسب على جهازك بمكتبة adhan.', 'Calculated on your device with the adhan library.', 'MIT'),
  _Credit('الخطوط', 'Fonts', 'Amiri و Amiri Quran (خالد حسني)، IBM Plex Sans Arabic، Plus Jakarta Sans.', 'Amiri and Amiri Quran (Khaled Hosny), IBM Plex Sans Arabic, Plus Jakarta Sans.', 'SIL OFL 1.1'),
];

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.noor;
    final ar = NoorFormat.isAr(context);
    return ServiceScaffold(title: NoorFormat.tr(context, 'حول نور', 'About NOOR'), children: [
      HeroSurface(
        radius: 28,
        child: Column(spacing: 8, children: [
          const EightPointStar(size: 52, color: NoorTokens.onHeroAccent, strokeWidth: 1.4),
          Text('نور · NOOR', style: NoorText.display(context, size: 30, color: Colors.white)),
          Text(NoorFormat.tr(context, 'القرآن والصلاة والأذكار في تطبيق واحد — يعمل دون اتصال في معظمه.', 'Quran, prayer times and adhkar in one app — mostly working offline.'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xD9FFFFFF), height: 1.6)),
          Text('${NoorFormat.tr(context, 'الإصدار', 'Version')} $appVersion', style: const TextStyle(color: NoorTokens.onHeroAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 16),
      SectionTitle(NoorFormat.tr(context, 'المصادر والإسناد', 'Sources and credits')),
      const SizedBox(height: 10),
      for (final c in credits)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: NoorCard(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: [
              Row(children: [
                Expanded(child: Text(ar ? c.titleAr : c.titleEn, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: t.goldSoft, borderRadius: BorderRadius.circular(99)), child: Text(c.licence, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.goldText))),
              ]),
              Text(ar ? c.bodyAr : c.bodyEn, style: TextStyle(height: 1.7, color: t.textSecondary, fontSize: 13.5)),
            ]),
          ),
        ),
      NoorCard(
        onTap: () => showLicensePage(context: context, applicationName: 'NOOR | نور', applicationVersion: appVersion),
        child: Row(spacing: 12, children: [
          const IconBadge(icon: Icons.description_outlined, size: 40),
          Expanded(child: Text(NoorFormat.tr(context, 'تراخيص المكتبات مفتوحة المصدر', 'Open-source licences'), style: const TextStyle(fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right_rounded, color: t.textSecondary),
        ]),
      ),
      const SizedBox(height: 12),
      Text(NoorFormat.tr(context, 'المحتوى الديني للتعلّم والتذكير وليس بديلًا عن أهل العلم. راجع مصادرك الموثوقة في المسائل الخاصة.', 'Religious content is for learning and reminding, not a substitute for scholars. Consult trusted sources for personal rulings.'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
