import 'prayer_models.dart';

/// Offline city list for the manual location picker. Only cities whose
/// country does not observe daylight saving are listed, because each entry
/// carries a fixed UTC offset used to display its prayer times. Anywhere else
/// is covered by the GPS option, which uses the device time zone.
const prayerCities = <PrayerLocation>[
  PrayerLocation(nameAr: 'مكة المكرمة، السعودية', nameEn: 'Makkah, Saudi Arabia', latitude: 21.3891, longitude: 39.8579, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation(nameAr: 'المدينة المنورة، السعودية', nameEn: 'Madinah, Saudi Arabia', latitude: 24.4686, longitude: 39.6142, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation(nameAr: 'الرياض، السعودية', nameEn: 'Riyadh, Saudi Arabia', latitude: 24.7136, longitude: 46.6753, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation(nameAr: 'جدة، السعودية', nameEn: 'Jeddah, Saudi Arabia', latitude: 21.4858, longitude: 39.1925, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation.dammam,
  PrayerLocation(nameAr: 'أبها، السعودية', nameEn: 'Abha, Saudi Arabia', latitude: 18.2164, longitude: 42.5053, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation(nameAr: 'تبوك، السعودية', nameEn: 'Tabuk, Saudi Arabia', latitude: 28.3838, longitude: 36.5550, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation(nameAr: 'بريدة، السعودية', nameEn: 'Buraydah, Saudi Arabia', latitude: 26.3260, longitude: 43.9750, utcOffsetMinutes: 180, method: PrayerMethod.ummAlQura),
  PrayerLocation(nameAr: 'دبي، الإمارات', nameEn: 'Dubai, UAE', latitude: 25.2048, longitude: 55.2708, utcOffsetMinutes: 240, method: PrayerMethod.dubai),
  PrayerLocation(nameAr: 'أبوظبي، الإمارات', nameEn: 'Abu Dhabi, UAE', latitude: 24.4539, longitude: 54.3773, utcOffsetMinutes: 240, method: PrayerMethod.dubai),
  PrayerLocation(nameAr: 'الدوحة، قطر', nameEn: 'Doha, Qatar', latitude: 25.2854, longitude: 51.5310, utcOffsetMinutes: 180, method: PrayerMethod.qatar),
  PrayerLocation(nameAr: 'الكويت، الكويت', nameEn: 'Kuwait City, Kuwait', latitude: 29.3759, longitude: 47.9774, utcOffsetMinutes: 180, method: PrayerMethod.kuwait),
  PrayerLocation(nameAr: 'المنامة، البحرين', nameEn: 'Manama, Bahrain', latitude: 26.2285, longitude: 50.5860, utcOffsetMinutes: 180, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'مسقط، عُمان', nameEn: 'Muscat, Oman', latitude: 23.5880, longitude: 58.3829, utcOffsetMinutes: 240, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'عمّان، الأردن', nameEn: 'Amman, Jordan', latitude: 31.9454, longitude: 35.9284, utcOffsetMinutes: 180, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'دمشق، سوريا', nameEn: 'Damascus, Syria', latitude: 33.5138, longitude: 36.2765, utcOffsetMinutes: 180, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'بغداد، العراق', nameEn: 'Baghdad, Iraq', latitude: 33.3152, longitude: 44.3661, utcOffsetMinutes: 180, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'صنعاء، اليمن', nameEn: 'Sanaa, Yemen', latitude: 15.3694, longitude: 44.1910, utcOffsetMinutes: 180, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'إسطنبول، تركيا', nameEn: 'Istanbul, Türkiye', latitude: 41.0082, longitude: 28.9784, utcOffsetMinutes: 180, method: PrayerMethod.turkey),
  PrayerLocation(nameAr: 'أنقرة، تركيا', nameEn: 'Ankara, Türkiye', latitude: 39.9334, longitude: 32.8597, utcOffsetMinutes: 180, method: PrayerMethod.turkey),
  PrayerLocation(nameAr: 'الخرطوم، السودان', nameEn: 'Khartoum, Sudan', latitude: 15.5007, longitude: 32.5599, utcOffsetMinutes: 120, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'طرابلس، ليبيا', nameEn: 'Tripoli, Libya', latitude: 32.8872, longitude: 13.1913, utcOffsetMinutes: 120, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'تونس، تونس', nameEn: 'Tunis, Tunisia', latitude: 36.8065, longitude: 10.1815, utcOffsetMinutes: 60, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'الجزائر، الجزائر', nameEn: 'Algiers, Algeria', latitude: 36.7538, longitude: 3.0588, utcOffsetMinutes: 60, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'مقديشو، الصومال', nameEn: 'Mogadishu, Somalia', latitude: 2.0469, longitude: 45.3182, utcOffsetMinutes: 180, method: PrayerMethod.muslimWorldLeague),
  PrayerLocation(nameAr: 'كراتشي، باكستان', nameEn: 'Karachi, Pakistan', latitude: 24.8607, longitude: 67.0011, utcOffsetMinutes: 300, method: PrayerMethod.karachi),
  PrayerLocation(nameAr: 'لاهور، باكستان', nameEn: 'Lahore, Pakistan', latitude: 31.5204, longitude: 74.3587, utcOffsetMinutes: 300, method: PrayerMethod.karachi),
  PrayerLocation(nameAr: 'دكا، بنغلاديش', nameEn: 'Dhaka, Bangladesh', latitude: 23.8103, longitude: 90.4125, utcOffsetMinutes: 360, method: PrayerMethod.karachi),
  PrayerLocation(nameAr: 'جاكرتا، إندونيسيا', nameEn: 'Jakarta, Indonesia', latitude: -6.2088, longitude: 106.8456, utcOffsetMinutes: 420, method: PrayerMethod.singapore),
  PrayerLocation(nameAr: 'كوالالمبور، ماليزيا', nameEn: 'Kuala Lumpur, Malaysia', latitude: 3.1390, longitude: 101.6869, utcOffsetMinutes: 480, method: PrayerMethod.karachi),
];
