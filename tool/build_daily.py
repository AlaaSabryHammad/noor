"""Builds assets/data/daily.json: rotating "Daily light" items for the home screen.

  ayah   – well-known ayahs, text and translation taken verbatim from assets/data/quran
  hadith – the shorter hadith of the Forty of an-Nawawi (assets/data/books/nawawi.json)
  dua    – the Quranic supplications already built into assets/data/adhkar.json

Run after build_adhkar.py / build_books.py:  python -X utf8 tool/build_daily.py
"""
import json
import sys

root = sys.argv[1] if len(sys.argv) > 1 else "."
AR_DIGITS = "٠١٢٣٤٥٦٧٨٩"


def ard(n):
    return "".join(AR_DIGITS[int(c)] for c in str(n))


index = json.load(open(f"{root}/assets/data/quran/index.json", encoding="utf-8"))
names = {s["number"]: s for s in index["surahs"]}


def surah(n):
    return json.load(open(f"{root}/assets/data/quran/{n:03d}.json", encoding="utf-8"))


def ayah_item(s, a, b=None):
    b = b or a
    rows = surah(s)[a - 1:b]
    rng_ar, rng_en = (ard(a), f"{a}") if a == b else (f"{ard(a)}-{ard(b)}", f"{a}-{b}")
    return {
        "ar": " ".join(r["ar"] for r in rows),
        "en": " ".join(r["en"] for r in rows),
        "refAr": f"سورة {names[s]['nameAr']} · الآية {rng_ar}",
        "refEn": f"{names[s]['nameEn']} {s}:{rng_en}",
        "quranic": True,
    }


AYAHS = [
    (13, 28), (2, 152), (2, 153), (2, 186), (2, 255), (2, 286), (3, 139), (3, 159), (3, 173), (4, 103),
    (6, 162, 163), (9, 51), (14, 7), (16, 97), (17, 9), (20, 14), (24, 35), (29, 69), (33, 41, 42), (39, 53),
    (39, 10), (40, 60), (49, 13), (51, 56), (57, 4), (59, 22, 24), (65, 2, 3), (93, 3, 5), (94, 5, 6), (112, 1, 4),
    (2, 45), (8, 2), (13, 11), (3, 200), (31, 17), (25, 63), (18, 46), (42, 40), (67, 2), (55, 13),
]
ayah = [ayah_item(*r) for r in AYAHS]

nawawi = json.load(open(f"{root}/assets/data/books/nawawi.json", encoding="utf-8"))
hadith = []
for h in nawawi:
    if len(h["ar"]) <= 380 and h["en"]:
        hadith.append({
            "ar": h["ar"], "en": h["en"],
            "refAr": f"الأربعون النووية · الحديث {ard(h['n'])}",
            "refEn": f"Forty Hadith an-Nawawi · {h['n']}",
            "quranic": False,
        })

for h in json.load(open(f"{root}/assets/data/hadith.json", encoding="utf-8"))["items"]:
    if len(h["ar"]) <= 380:
        hadith.append({"ar": h["ar"], "en": h["en"], "refAr": h["sourceAr"], "refEn": h["sourceEn"], "quranic": False})

adhkar = json.load(open(f"{root}/assets/data/adhkar.json", encoding="utf-8"))
dua = [{"ar": d["ar"], "en": d["en"], "refAr": d["sourceAr"], "refEn": d["sourceEn"], "quranic": True} for d in adhkar["quran_duas"] if len(d["ar"]) <= 420]

json.dump({"_note": "Quranic items copied verbatim from assets/data/quran; hadith from the bundled Forty an-Nawawi.", "ayah": ayah, "hadith": hadith, "dua": dua},
          open(f"{root}/assets/data/daily.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(ayah), "ayahs,", len(hadith), "hadith,", len(dua), "duas")
