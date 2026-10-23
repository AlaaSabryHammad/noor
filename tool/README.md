# Build scripts

Run everything from the project root with Python 3 (`python -I tool/<script>.py`). The generated JSON/PNG files are committed, so you only need these when changing content.

| Script | Produces |
|---|---|
| `build_quran_from_tanzil.py <tanzil-dir> <out.json>` | One combined Quran file from the Tanzil downloads (text, `en.sahih` translation, quran-data metadata). Pre-processing step. |
| `split_quran.py .` | Splits that file into `assets/data/quran/index.json` + `001.json … 114.json`. |
| `build_adhkar.py .` | `assets/data/adhkar.json` (Quranic items are copied from the Quran files). |
| `build_names.py .` | `assets/data/names.json` (99 names). |
| `build_hadith_seerah.py .` | `assets/data/hadith.json`, `seerah.json`. |
| `build_learn.py .` | `stories`, `academy`, `faq`, `hajj`, `kids` JSON. |
| `build_books.py` | `assets/data/books/*` from the open hadith-api dataset (needs internet). |
| `make_icons.py` | App icon: `assets/icon/noor_icon.png`, Android mipmaps, iOS AppIcon set (needs Pillow). |
