# ルートで実行
python3 - <<'PY'
import json, os
base = "movies/mp4"
items = []
for name in sorted(os.listdir(base)):
    if name.lower().endswith(".mp4"):
        items.append(f"{base}/{name}")
with open("videos.json", "w", encoding="utf-8") as f:
    json.dump(items, f, ensure_ascii=False, indent=2)
print(f"Wrote videos.json with {len(items)} items")
PY
y