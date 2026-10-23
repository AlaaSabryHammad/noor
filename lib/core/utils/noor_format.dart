import 'package:flutter/widgets.dart';
import 'package:hijri/hijri_calendar.dart';

/// Locale-aware formatting. Arabic UI uses Arabic-Indic digits by default.
abstract final class NoorFormat {
  static const _arDigits = '٠١٢٣٤٥٦٧٨٩';

  static bool isAr(BuildContext c) => Localizations.localeOf(c).languageCode == 'ar';

  /// Picks the Arabic or English string. Used for screen-specific copy that
  /// has not been moved into the ARB files.
  static String tr(BuildContext c, String ar, String en) => isAr(c) ? ar : en;

  static String digits(BuildContext c, Object value) {
    final s = value.toString();
    if (!isAr(c)) return s;
    return s.replaceAllMapped(RegExp(r'\d'), (m) => _arDigits[int.parse(m[0]!)]);
  }

  /// Arabic-Indic (and Persian) digits → Latin, for parsing user input.
  static String latinDigits(String s) => s.replaceAllMapped(RegExp('[٠-٩۰-۹]'), (m) {
        final c = m[0]!.codeUnitAt(0);
        return '${c >= 0x06F0 ? c - 0x06F0 : c - 0x0660}';
      });

  /// 12-hour clock: "٤:٢٢ ص" / "4:22 AM".
  static String time(BuildContext c, DateTime t, {bool withPeriod = true}) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final core = '$h12:${t.minute.toString().padLeft(2, '0')}';
    if (!withPeriod) return digits(c, core);
    final pm = t.hour >= 12;
    return isAr(c) ? '${digits(c, core)} ${pm ? 'م' : 'ص'}' : '$core ${pm ? 'PM' : 'AM'}';
  }

  /// Always Latin tabular digits, LTR — used for big countdowns.
  static String countdown(Duration d) {
    final s = d.isNegative ? Duration.zero : d;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(s.inHours)}:${two(s.inMinutes % 60)}:${two(s.inSeconds % 60)}';
  }

  static const _hijriAr = ['محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'];
  static const _hijriEn = ['Muharram', 'Safar', 'Rabi‘ al-Awwal', 'Rabi‘ al-Akhir', 'Jumada al-Ula', 'Jumada al-Akhirah', 'Rajab', 'Sha‘ban', 'Ramadan', 'Shawwal', 'Dhu al-Qa‘dah', 'Dhu al-Hijjah'];
  static const _gregAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  static const _gregEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _daysAr = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
  static const _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static String hijriMonth(BuildContext c, int month) => isAr(c) ? _hijriAr[month - 1] : _hijriEn[month - 1];
  static String gregMonth(BuildContext c, int month) => isAr(c) ? _gregAr[month - 1] : _gregEn[month - 1];

  /// Umm al-Qura based Hijri date. [offsetDays] is the user's ±1 adjustment.
  static HijriCalendar hijri(DateTime date, {int offsetDays = 0}) => HijriCalendar.fromDate(date.add(Duration(days: offsetDays)));

  /// "الجمعة ١٢ جمادى الأولى ١٤٤٨ هـ · ٢٣ أكتوبر ٢٠٢٦ م"
  static String fullDateLine(BuildContext c, DateTime date, {int hijriOffset = 0}) {
    final h = hijri(date, offsetDays: hijriOffset);
    if (isAr(c)) {
      return digits(c, '${_daysAr[date.weekday - 1]} ${h.hDay} ${_hijriAr[h.hMonth - 1]} ${h.hYear} هـ · ${date.day} ${_gregAr[date.month - 1]} ${date.year} م');
    }
    return '${_daysEn[date.weekday - 1]}, ${h.hDay} ${_hijriEn[h.hMonth - 1]} ${h.hYear} AH · ${date.day} ${_gregEn[date.month - 1]} ${date.year}';
  }
}
