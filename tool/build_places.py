"""Builds assets/data/places.json: an offline list of cities for naming the device location.

The phone's map service (Android Geocoder) is missing on many devices (Huawei without Google services, for
example), and then the app could only guess "the nearest of 29 listed cities". This list names any position
without internet, as the nearest populated place.

Source: GeoNames (https://www.geonames.org), licence CC BY 4.0 (credited in the app, Settings > About).
Download cities5000.zip and countryInfo.txt from https://download.geonames.org/export/dump/ into a folder of
their own, unzip cities5000.txt there, then:

    python -X utf8 -I tool/build_places.py <folder with the GeoNames files> .

Each place is [english name, arabic name, latitude, longitude, ISO country code]. The Arabic name is the first
Arabic-script alternate name GeoNames lists (blank when it has none: the app then shows the English one).
"""
import json
import re
import sys

src = sys.argv[1]
root = sys.argv[2] if len(sys.argv) > 2 else "."

# Countries where towns of 5,000 people matter (Muslim-majority or large Muslim communities); elsewhere 15,000.
SMALL_TOWNS = set(
    "SA AE KW QA BH OM YE IQ SY JO LB PS EG LY TN DZ MA MR SD SS SO DJ KM TR IR AF PK BD ID MY BN MV UZ KZ KG TJ TM "
    "AZ AL XK BA NE NG SN ML GM GN BF TD CM ER ET IN LK TH PH RU CN GB FR DE US CA AU NL BE SE".split()
)

# Arabic names of the countries the app is most likely to meet; other countries show their English name.
COUNTRY_AR = {
    "SA": "المملكة العربية السعودية", "AE": "الإمارات العربية المتحدة", "KW": "الكويت", "QA": "قطر", "BH": "البحرين",
    "OM": "عُمان", "YE": "اليمن", "IQ": "العراق", "SY": "سوريا", "JO": "الأردن", "LB": "لبنان", "PS": "فلسطين",
    "EG": "مصر", "LY": "ليبيا", "TN": "تونس", "DZ": "الجزائر", "MA": "المغرب", "MR": "موريتانيا", "SD": "السودان",
    "SS": "جنوب السودان", "SO": "الصومال", "DJ": "جيبوتي", "KM": "جزر القمر", "TR": "تركيا", "IR": "إيران",
    "AF": "أفغانستان", "PK": "باكستان", "BD": "بنغلاديش", "ID": "إندونيسيا", "MY": "ماليزيا", "BN": "بروناي",
    "MV": "جزر المالديف", "UZ": "أوزبكستان", "KZ": "كازاخستان", "KG": "قيرغيزستان", "TJ": "طاجيكستان",
    "TM": "تركمانستان", "AZ": "أذربيجان", "AL": "ألبانيا", "XK": "كوسوفو", "BA": "البوسنة والهرسك", "NE": "النيجر",
    "NG": "نيجيريا", "SN": "السنغال", "ML": "مالي", "GM": "غامبيا", "GN": "غينيا", "BF": "بوركينا فاسو",
    "TD": "تشاد", "CM": "الكاميرون", "ER": "إريتريا", "ET": "إثيوبيا", "IN": "الهند", "LK": "سريلانكا",
    "TH": "تايلاند", "PH": "الفلبين", "RU": "روسيا", "CN": "الصين", "GB": "المملكة المتحدة", "FR": "فرنسا",
    "DE": "ألمانيا", "US": "الولايات المتحدة", "CA": "كندا", "AU": "أستراليا", "NL": "هولندا", "BE": "بلجيكا",
    "SE": "السويد", "ES": "إسبانيا", "IT": "إيطاليا", "CH": "سويسرا", "AT": "النمسا", "NO": "النرويج",
    "DK": "الدنمارك", "BR": "البرازيل", "ZA": "جنوب أفريقيا", "KE": "كينيا", "TZ": "تنزانيا", "GH": "غانا",
    "JP": "اليابان", "KR": "كوريا الجنوبية", "SG": "سنغافورة", "NZ": "نيوزيلندا", "MX": "المكسيك", "AR": "الأرجنتين",
}

MARKS = re.compile("[‎‏‪-‮]")  # invisible direction marks GeoNames leaves after some names
ARABIC = re.compile(r"^[ء-غف-يٱ \-'’]+$")  # Arabic letters only, no diacritics
ARABIC_SCRIPT = re.compile(r"^[ء-يٱپچژکگھہیےە \-'’]+$")  # + Persian / Urdu letters
SKIP_PREFIXES = ("مدينة ", "محافظة ", "بلدية ", "قضاء ", "منطقة ", "مركز ", "إمارة ")


ARAB_WORLD = set("SA AE KW QA BH OM YE IQ SY JO LB PS EG LY TN DZ MA MR SD SO DJ KM".split())


def arabic_name(alternates, country):
    """A plain-Arabic alternate name; else one in Persian / Urdu letters (Iran, Pakistan, ...).

    In the Arab world GeoNames lists the usual spelling first and the full official one later ("مكة" then
    "مكة المكرمة"), so the fullest is taken. Elsewhere the alternates are transliterations of varying quality
    (London: "لأندأن", "لندن"), and the shortest is the safest."""
    names = [MARKS.sub("", a).strip() for a in alternates.split(",")]
    names = [a for a in names if 2 <= len(a) <= 28 and not a.startswith(SKIP_PREFIXES)]
    for pattern in (ARABIC, ARABIC_SCRIPT):
        found = [a for a in names if pattern.match(a)]
        if found:
            if country in ARAB_WORLD:
                return max(found, key=lambda a: (len(a), -found.index(a)))
            return min(found, key=lambda a: (len(a), found.index(a)))
    return ""


countries = {}
for line in open(f"{src}/countryInfo.txt", encoding="utf-8"):
    if line.startswith("#") or not line.strip():
        continue
    c = line.rstrip("\n").split("\t")
    countries[c[0]] = c[4]

places, used = [], set()
for line in open(f"{src}/cities5000.txt", encoding="utf-8"):
    f = line.rstrip("\n").split("\t")
    name, alternates, lat, lng, fclass, fcode, cc, pop = f[1], f[3], float(f[4]), float(f[5]), f[6], f[7], f[8], int(f[14] or 0)
    # PPLX = a section of a larger city (a neighbourhood): the city itself is the better name. Also skip historical / abandoned / destroyed places.
    if fclass != "P" or fcode in ("PPLX", "PPLH", "PPLQ", "PPLW", "PPLR") or pop < (5000 if cc in SMALL_TOWNS else 15000):
        continue
    if re.search(r"\d", name):  # "Paris 04 Hôtel-de-Ville": city districts, not cities
        continue
    places.append([name, arabic_name(alternates, cc), round(lat, 3), round(lng, 3), cc])
    used.add(cc)

# Largest-first is not needed: the app takes the nearest place. Sorting by latitude only keeps the file stable.
places.sort(key=lambda p: (p[4], p[2], p[3], p[0]))
out = {
    "_note": "Places from GeoNames (CC BY 4.0), see tool/build_places.py.",
    "countries": {cc: [countries.get(cc, cc), COUNTRY_AR.get(cc, "")] for cc in sorted(used)},
    "places": places,
}
with open(f"{root}/assets/data/places.json", "w", encoding="utf-8") as fh:
    json.dump(out, fh, ensure_ascii=False, separators=(",", ":"))
print(len(places), "places,", len(used), "countries,", sum(1 for p in places if p[1]), "with an Arabic name")
