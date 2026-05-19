#!/usr/bin/env sh
# Rasterize icons/icon.svg → icons/icon-512.png (requires Python PIL + png export path).
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SVG="$ROOT/icons/icon.svg"
OUT="$ROOT/icons/icon-512.png"

if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w 512 -h 512 "$SVG" -o "$OUT"
elif command -v magick >/dev/null 2>&1; then
  magick -background none "$SVG" -resize 512x512 "$OUT"
elif command -v convert >/dev/null 2>&1; then
  convert -background none "$SVG" -resize 512x512 "$OUT"
else
  python3 - "$SVG" "$OUT" <<'PY'
import sys
try:
    import cairosvg
except ImportError:
    sys.exit('请安装 rsvg-convert、ImageMagick，或 pip install cairosvg')
cairosvg.svg2png(url=sys.argv[1], write_to=sys.argv[2], output_width=512, output_height=512)
PY
fi

echo "已生成: $OUT"
