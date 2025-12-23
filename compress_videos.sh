#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

CRF="${CRF:-28}"
PRESET="${PRESET:-medium}"
AUDIO_K="${AUDIO_K:-128k}"

echo "Compressing .mp4/.mov under: $ROOT"
echo "CRF=$CRF, PRESET=$PRESET, AUDIO_K=$AUDIO_K"
echo

# find結果をヌル区切りで安全に読む（スペース/日本語/記号OK）
find "$ROOT" -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 |
while IFS= read -r -d '' f; do
  echo ">> $f"

  # 拡張子・ベース名
  ext="${f##*.}"         # mp4 / mov / MP4 / MOV
  base="$(basename "$f")"
  base_noext="${base%.*}"

  # /tmp に一時ファイルを作る（macでも確実に書ける）
  tmp="/tmp/__tmp_compress_${base_noext}_$$.$RANDOM.${ext}"

  # 映像：H.264 / 音声：AAC（QuickTime互換寄り）
  # ※ QuickTimeで.movが開けない問題は -tag:v avc1 が効くことが多い
  if ! ffmpeg -hide_banner -loglevel error -y \
    -i "$f" \
    -map 0:v:0? -map 0:a:0? \
    -c:v libx264 -preset "$PRESET" -crf "$CRF" -pix_fmt yuv420p -tag:v avc1 \
    -c:a aac -b:a "$AUDIO_K" \
    -movflags +faststart \
    "$tmp"
  then
    echo "NG (ffmpeg failed): $f"
    rm -f "$tmp" || true
    echo
    continue
  fi

  # 変換に成功したら上書き（同名に置き換え）
  mv -f "$tmp" "$f"
  echo "OK (overwritten): $f"
  echo
done

echo "Done."
