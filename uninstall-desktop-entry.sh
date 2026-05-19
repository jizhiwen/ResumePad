#!/usr/bin/env sh
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$DESKTOP_DIR/resumepad.desktop"

if [ ! -f "$DESKTOP_FILE" ]; then
  echo "未安装桌面项: $DESKTOP_FILE"
  exit 0
fi

rm -f "$DESKTOP_FILE"
ICON_THEME="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
PIXMAP="${XDG_DATA_HOME:-$HOME/.local/share}/pixmaps/resumepad.png"
for size in 48 128 256 512; do
  rm -f "$ICON_THEME/${size}x${size}/apps/resumepad.png"
done
rm -f "$PIXMAP"
command -v gtk-update-icon-cache >/dev/null 2>&1 &&
  gtk-update-icon-cache -f -t "$ICON_THEME" 2>/dev/null || true
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "已移除: $DESKTOP_FILE"
echo "若已固定到 Dock，请手动取消固定。"
