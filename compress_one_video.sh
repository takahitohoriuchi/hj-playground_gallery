# #!/usr/bin/env bash
# set -euo pipefail

# FILE="${1:-}"

# if [[ -z "$FILE" ]]; then
#   echo "Usage: ./compress_one.sh ./movies/demo.mp4"
#   exit 1
# fi

# if [[ ! -f "$FILE" ]]; then
#   echo "ERROR: file not found: $FILE"
#   exit 1
# fi

# CRF="${CRF:-28}"
# PRESET="${PRESET:-medium}"
# AUDIO_K="${AUDIO_K:-128k}"

# command -v ffmpeg >/dev/null 2>&1 || {
#   echo "ERROR: ffmpeg が見つからんど。brew install ffmpeg してね。"
#   exit 1
# }

# echo "Compressing: $FILE"
# echo "CRF=${CRF}, PRESET=${PRESET}, AUDIO_K=${AUDIO_K}"

# dir="$(dirname "$FILE")"
# base="$(basename "$FILE")"
# ext="${base##*.}"
# ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

# tmp=""
# if tmp="$(mktemp -p "$dir" ".tmp_compress_XXXXXX.${ext_lc}" 2>/dev/null)"; then
#   :
# else
#   tmp="$(mktemp "/tmp/tmp_compress_XXXXXX.${ext_lc}")"
# fi

# ffmpeg -hide_banner -loglevel error -y \
#   -i "$FILE" \
#   -map 0:v:0 -map 0:a? \
#   -c:v libx264 -preset "$PRESET" -crf "$CRF" -pix_fmt yuv420p -tag:v avc1 \
#   -c:a aac -b:a "$AUDIO_K" \
#   -movflags +faststart \
#   "$tmp"

# mv -f "$tmp" "$FILE"
# echo "OK (overwritten): $FILE"

#!/usr/bin/env bash
set -euo pipefail

# ---- config (envで上書き可) ----
CRF="${CRF:-28}"
PRESET="${PRESET:-medium}"
AUDIO_K="${AUDIO_K:-128k}"

usage() {
  echo "Usage: $0 ./a/oldman1.mov"
  echo "Env: CRF=$CRF PRESET=$PRESET AUDIO_K=$AUDIO_K"
}

if [ $# -ne 1 ]; then
  usage
  exit 2
fi

IN="$1"

if [ ! -f "$IN" ]; then
  echo "Error: file not found: $IN" >&2
  exit 1
fi

# extを小文字化（bash 3.2対応）
ext="${IN##*.}"
ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

case "$ext_lc" in
  mp4|mov) ;;
  *)
    echo "Error: supported only .mp4 or .mov (got: .$ext)" >&2
    exit 1
    ;;
esac

dir="$(cd "$(dirname "$IN")" && pwd)"
base="$(basename "$IN")"
stem="${base%.*}"

# 出力先：mov→mp4 / mp4→mp4(上書き)
if [ "$ext_lc" = "mov" ]; then
  OUT="$dir/$stem.mp4"
else
  OUT="$dir/$base"
fi

# 一時ファイル（/tmp なら書ける）
tmp="/tmp/__tmp_compress_${stem}_$$.$RANDOM.mp4"

echo "Input : $IN"
echo "Output: $OUT"
echo "CRF=$CRF, PRESET=$PRESET, AUDIO_K=$AUDIO_K"
echo

# 映像：H.264 / 音声：AAC（QuickTime互換寄り）
# -tag:v avc1 が QuickTime 互換に効くこと多い
ffmpeg -hide_banner -loglevel error -y \
  -i "$IN" \
  -map 0:v:0? -map 0:a:0? \
  -c:v libx264 -preset "$PRESET" -crf "$CRF" -pix_fmt yuv420p -tag:v avc1 \
  -c:a aac -b:a "$AUDIO_K" \
  -movflags +faststart \
  "$tmp"

# 成功したら置き換え
mv -f "$tmp" "$OUT"

# 入力がmovで、出力が別名mp4になった場合は元movを消す（=置き換え）
if [ "$ext_lc" = "mov" ] && [ "$IN" != "$OUT" ]; then
  rm -f "$IN"
fi

echo "OK (overwritten/converted): $OUT"
