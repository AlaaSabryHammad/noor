"""Builds assets/data/hisn.json: the complete Hisn al-Muslim (132 chapters, 267
adhkar) with Arabic text, English translation and repeat counts.

Source:  https://github.com/YousefAsalya/Islamic-Pro-azkar-API  (MIT licence)
         Hisn al-Muslim by Sheikh Sa'eed bin Ali bin Wahf al-Qahtani.

Run from the project root:  python -X utf8 tool/build_hisn.py   (needs internet)
"""
import json
import re
import sys
import unicodedata
import urllib.request

RAW = "https://raw.githubusercontent.com/YousefAsalya/Islamic-Pro-azkar-API/main/data"
OUT = "assets/data/hisn.json"

# Chapter ranges (book order) → themed groups shown in the app.
GROUPS = [
    (1, 15, "الاستيقاظ واللباس والخلاء والوضوء والبيت والمسجد والأذان", "Waking, clothing, wudu, home, mosque and adhan"),
    (16, 26, "الصلاة", "Prayer"),
    (27, 33, "الصباح والمساء والنوم والرؤيا والوتر", "Morning, evening, sleep, dreams and witr"),
    (34, 46, "الهم والكرب والخوف والدَّين والوسوسة", "Worry, distress, fear, debt and whispers"),
    (47, 60, "المولود والمرض والجنائز", "Newborn, illness and funerals"),
    (61, 67, "الريح والرعد والمطر والهلال", "Wind, thunder, rain and the new moon"),
    (68, 76, "الصيام والطعام والشراب", "Fasting, food and drink"),
    (77, 94, "العطاس والزواج والمجالس والمعاملات", "Sneezing, marriage, gatherings and dealings"),
    (95, 106, "الركوب والسفر", "Riding and travel"),
    (107, 114, "الصلاة على النبي والسلام والآداب", "Salawat, greetings and manners"),
    (115, 121, "الحج", "Hajj"),
    (122, 132, "الاستغفار والتسبيح وأدعية متنوعة", "Istighfar, tasbih and general supplications"),
]

DIACRITICS = re.compile(r"[ً-ٰٟـ]")
NUMBERS = {"ثلاث": 3, "أربع": 4, "اربع": 4, "خمس": 5, "ست": 6, "سبع": 7, "ثمان": 8, "تسع": 9, "عشر": 10, "مائة": 100, "مئة": 100}


def get(name):
    with urllib.request.urlopen(f"{RAW}/{name}.json", timeout=120) as r:
        return json.loads(r.read().decode("utf-8"))


def presentation(s):
    """Fold Arabic presentation-form glyphs (U+FB50–FDFF, U+FE70–FEFF) to plain letters."""
    return "".join(unicodedata.normalize("NFKC", c) if "ﭐ" <= c <= "﷿" or "ﹰ" <= c <= "﻿" else c for c in s)


def clean_ar(s):
    s = presentation(s).strip()
    s = s.replace("((", "«").replace("))", "»")
    return re.sub(r"[ \t]{2,}", " ", s)


def clean_en(s):
    return re.sub(r"[ \t]{2,}", " ", s).strip()


def repeat_of(text, count):
    """The dataset sometimes leaves count at 1 although the text ends with an explicit '(… times)'."""
    if count != 1:
        return count
    plain = DIACRITICS.sub("", text)
    m = re.search(r"\(\s*(ثلاث|أربع|اربع|خمس|ست|سبع|ثمان|تسع|عشر|مائة|مئة)\s*مر(?:ة|ات)\s*\)\s*\.?\s*$", plain)
    return NUMBERS[m.group(1)] if m else count


def group_of(cid):
    for a, b, ar, en in GROUPS:
        if a <= cid <= b:
            return GROUPS.index((a, b, ar, en)) + 1
    return len(GROUPS)


def main():
    ar, en = get("ar"), {c["id"]: c for c in get("en")}
    cats = []
    total = 0
    for c in ar:
        e = en[c["id"]]
        items = []
        en_items = {x["id"]: x for x in e["array"]}
        for it in c["array"]:
            text = clean_ar(it["text"])
            items.append({"id": it["id"], "ar": text, "en": clean_en(en_items[it["id"]]["text"]), "repeat": repeat_of(it["text"], it["count"])})
        total += len(items)
        cats.append({"id": c["id"], "group": group_of(c["id"]), "titleAr": clean_ar(c["category"]), "titleEn": clean_en(e["category"]), "items": items})
    out = {
        "_note": "Hisn al-Muslim by Sa'eed al-Qahtani. Data: github.com/YousefAsalya/Islamic-Pro-azkar-API (MIT). Chapter titles/texts as published there; repeat counts corrected where the text states them.",
        "groups": [{"id": i + 1, "titleAr": ar_, "titleEn": en_} for i, (_, _, ar_, en_) in enumerate(GROUPS)],
        "categories": cats,
    }
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    print(len(cats), "chapters,", total, "adhkar")


if __name__ == "__main__":
    sys.exit(main())
