"""Builds assets/data/audio.json: the reciter and radio catalogue from mp3quran.net.

The app ships this snapshot so the Audio section opens offline and instantly;
at run time it refreshes the same API responses in the background and keeps
the newer copy for the next launch. The file stores the API responses as they
are (Arabic and English), so the app parses one format for both.

  python -I tool/build_audio.py .        (needs internet)
"""
import json
import sys
import urllib.request

root = sys.argv[1] if len(sys.argv) > 1 else "."
API = "https://www.mp3quran.net/api/v3"


def get(path):
    req = urllib.request.Request(f"{API}/{path}", headers={"User-Agent": "noor-build/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


out = {
    "_note": "Reciter, radio, audio-tafsir and video catalogue from the mp3quran.net API v3 (https://www.mp3quran.net/api). Media is streamed from their servers.",
    "reciters": {"ar": get("reciters?language=ar")["reciters"], "en": get("reciters?language=eng")["reciters"]},
    "radios": {"ar": get("radios?language=ar")["radios"], "en": get("radios?language=eng")["radios"]},
    # Audio tafsir (al-Khulasa min Tafsir al-Tabari), one or more parts per surah.
    "tafsir": get("tafsir?tafsir=1&language=ar")["tafasir"],
    "videos": {"items": get("videos?language=ar")["videos"], "types": {"ar": get("video_types?language=ar")["video_types"], "en": get("video_types?language=eng")["video_types"]}},
}
# The surah list of a complete mushaf is the same 114 numbers every time; keep the file small.
full = ",".join(str(i) for i in range(1, 115))
for lang in ("ar", "en"):
    for r in out["reciters"][lang]:
        r.pop("date", None)
        for m in r["moshaf"]:
            if m["surah_list"] == full:
                m["surah_list"] = "all"
    for r in out["radios"][lang]:
        r.pop("recent_date", None)

with open(f"{root}/assets/data/audio.json", "w", encoding="utf-8") as f:
    json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
print(len(out["reciters"]["ar"]), "reciters,", len(out["radios"]["ar"]), "radios")
