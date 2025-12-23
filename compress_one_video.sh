#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
  echo "Usage: ./compress_one.sh ./movies/demo.mp4"
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "ERROR: file not found: $FILE"
  exit 1
fi

CRF="${CRF:-28}"
PRESET="${PRESET:-medium}"
AUDIO_K="${AUDIO_K:-128k}"

command -v ffmpeg >/dev/null 2>&1 || {
  echo "ERROR: ffmpeg が見つからんど。brew install ffmpeg してね。"
  exit 1
}

echo "Compressing: $FILE"
echo "CRF=${CRF}, PRESET=${PRESET}, AUDIO_K=${AUDIO_K}"

dir="$(dirname "$FILE")"
base="$(basename "$FILE")"
ext="${base##*.}"
ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

tmp=""
if tmp="$(mktemp -p "$dir" ".tmp_compress_XXXXXX.${ext_lc}" 2>/dev/null)"; then
  :
else
  tmp="$(mktemp "/tmp/tmp_compress_XXXXXX.${ext_lc}")"
fi

ffmpeg -hide_banner -loglevel error -y \
  -i "$FILE" \
  -map 0:v:0 -map 0:a? \
  -c:v libx264 -preset "$PRESET" -crf "$CRF" -pix_fmt yuv420p -tag:v avc1 \
  -c:a aac -b:a "$AUDIO_K" \
  -movflags +faststart \
  "$tmp"

mv -f "$tmp" "$FILE"
echo "OK (overwritten): $FILE"
