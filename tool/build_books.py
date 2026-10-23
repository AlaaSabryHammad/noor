"""Builds assets/data/books/* from the open hadith-api dataset.

Source:  https://github.com/fawazahmed0/hadith-api  (The Unlicense / public domain)
CDN:     https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1

Output:
  assets/data/books/catalog.json   books + section index (small)
  assets/data/books/<id>.json      full text (Arabic + English) for the bundled books

Run from the project root:  python tool/build_books.py
"""
import json
import os
import sys
import urllib.request

BASE = "https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1"
OUT = "assets/data/books"

# id → (Arabic title, English title, Arabic author, English author, Arabic blurb, English blurb)
BOOKS = {
    "nawawi": ("الأربعون النووية", "Forty Hadith of an-Nawawi", "الإمام النووي", "Imam an-Nawawi",
               "اثنان وأربعون حديثًا جامعة لأصول الدين جمعها الإمام النووي رحمه الله.",
               "Forty-two foundational hadith gathered by Imam an-Nawawi.", True),
    "qudsi": ("الأحاديث القدسية", "Forty Hadith Qudsi", "مجموعة محققة", "Compiled collection",
              "أحاديث يرويها النبي ﷺ عن ربه عز وجل.", "Hadith the Prophet ﷺ related from his Lord.", True),
    "dehlawi": ("الأربعون الدهلوية", "Forty Hadith of Shah Waliullah Dehlawi", "الشاه ولي الله الدهلوي", "Shah Waliullah Dehlawi",
                "أربعون حديثًا مسلسلة اختارها الشاه ولي الله الدهلوي.", "Forty hadith selected by Shah Waliullah Dehlawi.", True),
    "bukhari": ("صحيح البخاري", "Sahih al-Bukhari", "الإمام البخاري", "Imam al-Bukhari",
                "أصح الكتب بعد كتاب الله عند جمهور العلماء.", "Regarded as the most authentic book after the Quran.", False),
    "muslim": ("صحيح مسلم", "Sahih Muslim", "الإمام مسلم", "Imam Muslim",
               "ثاني الصحيحين وأحد أصح كتب الحديث.", "The second of the two Sahihs.", False),
    "abudawud": ("سنن أبي داود", "Sunan Abi Dawud", "الإمام أبو داود", "Imam Abu Dawud",
                 "من كتب السنن، عُني بأحاديث الأحكام.", "A Sunan collection focused on legal rulings.", False),
    "tirmidhi": ("جامع الترمذي", "Jami at-Tirmidhi", "الإمام الترمذي", "Imam at-Tirmidhi",
                 "جامع يبيّن درجة الأحاديث ومذاهب الفقهاء.", "A collection that grades its hadith and notes the jurists' views.", False),
    "nasai": ("سنن النسائي", "Sunan an-Nasa'i", "الإمام النسائي", "Imam an-Nasa'i",
              "من كتب السنن الستة، ودقيق في علل الأسانيد.", "One of the six books, careful about the chains.", False),
    "ibnmajah": ("سنن ابن ماجه", "Sunan Ibn Majah", "الإمام ابن ماجه", "Imam Ibn Majah",
                 "سادس الكتب الستة.", "The sixth of the six canonical books.", False),
    "malik": ("موطأ الإمام مالك", "Muwatta Malik", "الإمام مالك", "Imam Malik",
              "من أقدم كتب الحديث والفقه المدوّنة.", "One of the earliest compiled works of hadith and fiqh.", False),
}


def get(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return json.loads(r.read().decode("utf-8"))


def sections_of(meta):
    """[{n, title, first, last}] for every real section (skips the empty section 0)."""
    names = meta["sections"]
    details = meta.get("section_details", {})
    out = []
    for k, title in names.items():
        if k == "0" or not title:
            continue
        d = details.get(k, {})
        out.append({"n": int(k), "title": title, "first": d.get("hadithnumber_first"), "last": d.get("hadithnumber_last")})
    return sorted(out, key=lambda s: s["n"])


def arabic(s):
    """Some entries use Persian yeh/keheh; fold them to the Arabic letters the app fonts shape correctly."""
    return s.strip().replace("ی", "ي").replace("ک", "ك")


def grade_of(h):
    g = h.get("grades") or []
    return g[0]["grade"] if g and isinstance(g[0], dict) and g[0].get("grade") else ""


def main():
    os.makedirs(OUT, exist_ok=True)
    info = get(f"{BASE}/info.json")
    catalog = []
    for bid, (tar, ten, aar, aen, bar, ben, bundled) in BOOKS.items():
        meta = info[bid]["metadata"]
        secs = sections_of(meta)
        entry = {"id": bid, "titleAr": tar, "titleEn": ten, "authorAr": aar, "authorEn": aen, "blurbAr": bar, "blurbEn": ben,
                 "bundled": bundled, "sections": secs}
        if bundled:
            ar = get(f"{BASE}/editions/ara-{bid}.min.json")["hadiths"]
            en = {h["hadithnumber"]: h for h in get(f"{BASE}/editions/eng-{bid}.min.json")["hadiths"]}
            ranges = [(s["n"], s["first"], s["last"]) for s in secs]
            hadiths = []
            for h in ar:
                n = h["hadithnumber"]
                sec = next((s for s, a, b in ranges if a is not None and a <= n <= b), secs[0]["n"] if secs else 1)
                e = en.get(n, {})
                hadiths.append({"n": n, "s": sec, "ar": arabic(h["text"]), "en": (e.get("text") or "").strip(), "g": grade_of(h) or grade_of(e)})
            entry["count"] = len(hadiths)
            with open(f"{OUT}/{bid}.json", "w", encoding="utf-8") as f:
                json.dump(hadiths, f, ensure_ascii=False, separators=(",", ":"))
            print(bid, "bundled", len(hadiths))
        else:
            entry["count"] = max((s["last"] or 0) for s in secs) if secs else 0
            print(bid, "online index", len(secs), "sections")
        catalog.append(entry)
    with open(f"{OUT}/catalog.json", "w", encoding="utf-8") as f:
        json.dump({"_note": "Hadith text: github.com/fawazahmed0/hadith-api (The Unlicense). Section titles are in English as published by the dataset.",
                   "base": BASE, "books": catalog}, f, ensure_ascii=False, separators=(",", ":"))


if __name__ == "__main__":
    sys.exit(main())
