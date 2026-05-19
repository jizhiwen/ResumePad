#!/usr/bin/env sh
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$DESKTOP_DIR/resumepad.desktop"

if [ ! -f "$DESKTOP_FILE" ]; then
  echo "未安装桌面项: $DESKTOP_FILE"
  exit 0
fi

rm -f "$DESKTOP_FILE"
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "已移除: $DESKTOP_FILE"
echo "若已固定到 Dock，请手动取消固定。"
