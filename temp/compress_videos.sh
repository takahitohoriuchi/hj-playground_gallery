#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"

CRF="${CRF:-28}"
PRESET="${PRESET:-medium}"
AUDIO_K="${AUDIO_K:-128k}"

echo "Compress/convert .mp4/.mov under: $ROOT"
echo "CRF=$CRF, PRESET=$PRESET, AUDIO_K=$AUDIO_K"
echo

# 一時ディレクトリ（mac想定）
TMPBASE="${TMPDIR:-/tmp}"
if [[ ! -d "$TMPBASE" || ! -w "$TMPBASE" ]]; then
  TMPBASE="/tmp"
fi

# find結果をヌル区切りで安全に読む（スペース/日本語/記号OK）
find "$ROOT" -type f \( -iname "*.mp4" -o -iname "*.mov" \) -print0 |
while IFS= read -r -d '' f; do
  echo ">> $f"

  # 拡張子（小文字化）
  ext="${f##*.}"
  ext_lc="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

  dir="$(dirname "$f")"
  base="$(basename "$f")"
  base_noext="${base%.*}"

  # 出力は常に mp4
  out="${dir}/${base_noext}.mp4"

  # 一時ファイル（同じディレクトリだと権限で死ぬことがあるのでTMPへ）
  tmp="${TMPBASE}/__tmp_compress_${base_noext}_$$.$RANDOM.mp4"

  # H.264 は偶数解像度が安全（特に yuv420p）
  # ここで必ず幅/高さを偶数に丸める
  VF_SCALE_EVEN='scale=trunc(iw/2)*2:trunc(ih/2)*2'

  # 変換/圧縮
  # - 映像: H.264 (libx264) + yuv420p + avc1 tag (QuickTime互換寄り)
  # - 音声: AAC (なければ無音でOK)
  # - +faststart: moov atom を先頭へ（Web/QuickTimeで開きやすい）
  if ! ffmpeg -hide_banner -loglevel error -y \
    -i "$f" \
    -map 0:v:0? -map 0:a:0? \
    -vf "$VF_SCALE_EVEN" \
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

  # 置き換え
  mv -f "$tmp" "$out"

  # 元が .mov なら削除（.mp4化）
  if [[ "$ext_lc" == "mov" ]]; then
    rm -f "$f" || true
    echo "OK: $f  ->  $out (mov deleted)"
  else
    echo "OK (overwritten): $out"
  fi
  echo
done

echo "Done."
