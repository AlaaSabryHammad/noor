import json, re, sys
src, out = sys.argv[1], sys.argv[2]

def lines(name):
    with open(f"{src}/{name}", encoding="utf-8") as f:
        return [l.rstrip("\n") for l in f]

def parse(name):
    d = {}
    for l in lines(name):
        if not l or l.startswith("#"):
            continue
        s, a, t = l.split("|", 2)
        d[(int(s), int(a))] = t
    return d

ar, en = parse("quran.txt"), parse("en.txt")
assert len(ar) == 6236 and len(en) == 6236, (len(ar), len(en))

meta = "\n".join(lines("meta.js"))

def block(name):
    m = re.search(r"QuranData\.%s = \[(.*?)\n\];" % name, meta, re.S)
    return m.group(1)

def pairs(name):
    return [(int(a), int(b)) for a, b in re.findall(r"\[(\d+),\s*(\d+)\]", block(name))]

pages = pairs("Page")          # index 0 = page 1; last entry is the [115,1] sentinel
juz = pairs("Juz")
assert len(pages) == 605 and len(juz) == 31, (len(pages), len(juz))
pages = pages[:604]
juz = juz[:30]

suras = []
for m in re.finditer(r"\[(\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*'([^']*)',\s*\"([^\"]*)\",\s*'([^']*)',\s*'([^']*)'\]", block("Sura")):
    suras.append(m.groups())
assert len(suras) == 114

def page_of(s, a):
    p = 1
    for i, pos in enumerate(pages):
        if pos <= (s, a):
            p = i + 1
    return p

BSM = ar[(1, 1)] + " "
text = {}
surahs = []
for i, g in enumerate(suras, 1):
    n = int(g[1])
    items = []
    for a in range(1, n + 1):
        t = ar[(i, a)]
        # Tanzil prefixes the basmala to ayah 1 of every surah but 1 and 9;
        # the reader renders it in the surah header instead.
        if a == 1 and i not in (1, 9):
            # (95:1 carries a variant first word in the source, so match words 2-4.)
            w, b = t.split(" "), BSM.split()
            assert len(w) > 4 and w[1:4] == b[1:4], i
            t = " ".join(w[4:])
        items.append({"number": a, "ar": t, "en": en[(i, a)]})
    text[str(i)] = items
    surahs.append({
        "number": i, "nameAr": g[4], "nameEn": g[5],
        "revelation": g[7].lower(), "ayahCount": n, "startPage": page_of(i, 1),
    })

data = {
    "_note": "Quran text: Tanzil Uthmani v1.1, (c) 2007-2026 Tanzil Project, CC BY 3.0, http://tanzil.net. Translation: Saheeh International via Tanzil (en.sahih). Metadata: Tanzil quran-data. Text is unmodified except that the basmala prefixed to ayah 1 (surahs 2-114 except 9) is not repeated in ayah 1.",
    "surahs": surahs,
    "juz": [{"number": k + 1, "surah": s, "ayah": a, "page": page_of(s, a)} for k, (s, a) in enumerate(juz)],
    "pages": [[s, a] for s, a in pages],
    "text": text,
}
with open(out, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
print(len(surahs), len(data["juz"]), sum(len(v) for v in text.values()))
