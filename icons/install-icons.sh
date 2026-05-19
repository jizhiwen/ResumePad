#!/usr/bin/env sh
# Install ResumePad PNG icons (hicolor theme + pixmaps + repo favicons).
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
SRC="$ROOT/icons/icon-512.png"
ICON_THEME="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
PIXMAP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/pixmaps"

if [ ! -f "$SRC" ]; then
  echo "缺少 $SRC，请先运行 icons/generate-png.sh" >&2
  exit 1
fi

install_png() {
  src=$1
  dst=$2
  n=$3
  mkdir -p "$(dirname "$dst")"
  python3 - "$src" "$dst" "$n" <<'PY'
import sys
from PIL import Image

src, dst, n = sys.argv[1], sys.argv[2], int(sys.argv[3])
Image.open(src).convert('RGBA').resize((n, n), Image.LANCZOS).save(dst, optimize=True)
PY
}

for size in 48 128 256 512; do
  install_png "$SRC" "$ICON_THEME/${size}x${size}/apps/resumepad.png" "$size"
done
for size in 48 128 512; do
  install_png "$SRC" "$ROOT/icons/icon-${size}.png" "$size"
done

install_png "$SRC" "$PIXMAP_DIR/resumepad.png" 256

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$ICON_THEME" 2>/dev/null || true
fi

echo "图标已安装: hicolor (Icon=resumepad), pixmaps/resumepad.png, icons/icon-{48,128,512}.png"
