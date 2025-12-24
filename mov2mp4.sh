#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

CRF="${CRF:-28}"
PRESET="${PRESET:-medium}"
AUDIO_K="${AUDIO_K:-128k}"

echo "Convert ALL .mov -> .mp4 under: $ROOT"
echo "CRF=$CRF, PRESET=$PRESET, AUDIO_K=$AUDIO_K"
echo

# スペース/日本語/記号OK（ヌル区切り）
find "$ROOT" -type f \( -iname "*.mov" \) -print0 |
while IFS= read -r -d '' f; do
  echo ">> $f"

  dir="$(dirname "$f")"
  base="$(basename "$f")"
  base_noext="${base%.*}"

  out="$dir/$base_noext.mp4"

  # すでに同名mp4がある場合はスキップ（事故防止）
  if [[ -e "$out" ]]; then
    echo "SKIP: output already exists -> $out"
    echo
    continue
  fi

  # 一時ファイル（/tmp は mac でも書ける）
  tmp="/tmp/__tmp_mov2mp4_${base_noext}_$$.$RANDOM.mp4"

  # QuickTime互換寄り：H.264 + AAC + yuv420p + avc1
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

  # 成功したら：mp4を配置 → 元mov削除（＝置き換え）
  mv -f "$tmp" "$out"
  rm -f "$f"
  echo "OK: $f  ->  $out (mov deleted)"
  echo
done

echo "Done."
