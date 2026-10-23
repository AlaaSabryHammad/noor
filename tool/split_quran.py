import json, os, sys
root = sys.argv[1]
src = f"{root}/assets/data/quran.json"
d = json.load(open(src, encoding="utf-8"))
out = f"{root}/assets/data/quran"
os.makedirs(out, exist_ok=True)
index = {k: v for k, v in d.items() if k != "text"}
with open(f"{out}/index.json", "w", encoding="utf-8") as f:
    json.dump(index, f, ensure_ascii=False, separators=(",", ":"))
total = 0
for n in range(1, 115):
    items = d["text"][str(n)]
    total += len(items)
    with open(f"{out}/{n:03d}.json", "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, separators=(",", ":"))
assert total == 6236
print("ok", total, max(os.path.getsize(f"{out}/{n:03d}.json") for n in range(1, 115)))
