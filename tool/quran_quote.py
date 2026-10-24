"""Shared helpers for content scripts that quote the Quran.

Quranic text is never typed by hand: A() copies it from assets/data/quran
(Tanzil Uthmani + Saheeh International). An excerpt is cut by matching
words with the diacritics removed (their Unicode order varies), and the
original text is returned untouched; a phrase that does not match stops
the build.
"""
import json
import re

AR_DIGITS = "٠١٢٣٤٥٦٧٨٩"
MARKS = re.compile("[ؐ-ًؚ-ٰٟۖ-ۭـ]")


def ard(n):
    return "".join(AR_DIGITS[int(c)] if c.isdigit() else c for c in str(n))


class Quran:
    def __init__(self, root):
        self.root = root
        index = json.load(open(f"{root}/assets/data/quran/index.json", encoding="utf-8"))
        self.names = {s["number"]: s for s in index["surahs"]}
        self._surahs = {}

    def surah(self, n):
        if n not in self._surahs:
            self._surahs[n] = json.load(open(f"{self.root}/assets/data/quran/{n:03d}.json", encoding="utf-8"))
        return self._surahs[n]

    def A(self, s, a, b=None, ar_from=None, ar_to=None, en_from=None, en_to=None):
        """Quran block: ayahs s:a..b, optionally an exact excerpt."""
        b = b or a
        rows = self.surah(s)[a - 1 : b]
        assert len(rows) == b - a + 1, f"{s}:{a}-{b} out of range"
        ar = cut(" ".join(r["ar"] for r in rows), ar_from, ar_to, f"{s}:{a} ar")
        en = cut(" ".join(r["en"] for r in rows), en_from, en_to, f"{s}:{a} en")
        rng_ar, rng_en = (ard(a), f"{a}") if a == b else (f"{ard(a)}–{ard(b)}", f"{a}–{b}")
        return {"t": "ayah", "ar": ar, "en": en, "refAr": f"سورة {self.names[s]['nameAr']}: {rng_ar}", "refEn": f"{self.names[s]['nameEn']} {s}:{rng_en}"}


def bare(word):
    """A word without diacritics or Quranic marks, for matching only."""
    return MARKS.sub("", word).replace("ٱ", "ا").strip(".,;:!?\"'()[]-")


def cut(text, start, end, what):
    """Exact excerpt of `text`, from the words of `start` through the words of `end`."""
    words = text.split()
    keys = [bare(w) for w in words]

    def find(phrase, after=0):
        p = [bare(w) for w in phrase.split()]
        for i in range(after, len(words) - len(p) + 1):
            if keys[i : i + len(p)] == p:
                return i, i + len(p)
        raise AssertionError(f"{what}: {phrase!r} not found")

    lo = find(start)[0] if start else 0
    hi = find(end, lo)[1] if end else len(words)
    out = " ".join(words[lo:hi])
    # A cut can leave half of a quoted sentence; drop the orphaned quote mark.
    return out.strip('"') if out.count('"') % 2 else out


def H(ar, en, ref_ar, ref_en):
    return {"t": "hadith", "ar": ar, "en": en, "refAr": ard(ref_ar), "refEn": ref_en}


def P(ar, en):
    return {"t": "p", "ar": ar, "en": en}
