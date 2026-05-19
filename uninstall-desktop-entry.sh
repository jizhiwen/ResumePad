#!/usr/bin/env sh
# 卸载 ResumePad 桌面应用（不删除 ~/.config/ResumePad 用户数据）。
set -e

DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$DESKTOP_DIR/resumepad.desktop"
PREFIX="${RESUMEPAD_PREFIX:-$HOME/.local/opt/resumepad}"
BIN_LINK="${HOME}/.local/bin/resumepad"
ICON_THEME="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
PIXMAP="${XDG_DATA_HOME:-$HOME/.local/share}/pixmaps/resumepad.png"

rm -f "$DESKTOP_FILE" "$BIN_LINK"
rm -rf "$PREFIX"

for size in 48 128 256 512; do
  rm -f "$ICON_THEME/${size}x${size}/apps/resumepad.png"
done
rm -f "$PIXMAP"

command -v gtk-update-icon-cache >/dev/null 2>&1 &&
  gtk-update-icon-cache -f -t "$ICON_THEME" 2>/dev/null || true
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "已卸载 ResumePad 程序与桌面项（保留用户数据 ~/.config/ResumePad）。"
echo "若已固定到 Dock，请手动取消固定。"
