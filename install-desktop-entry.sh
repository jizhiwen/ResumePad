#!/usr/bin/env sh
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$DESKTOP_DIR/resumepad.desktop"
LAUNCHER="$ROOT/launch-app.sh"
ICON="$ROOT/icons/icon-512.png"

if ! command -v microsoft-edge >/dev/null 2>&1 &&
  ! command -v microsoft-edge-stable >/dev/null 2>&1 &&
  ! command -v msedge >/dev/null 2>&1; then
  echo "未找到 Microsoft Edge，请先安装 Edge。"
  exit 1
fi

chmod +x "$LAUNCHER"

mkdir -p "$DESKTOP_DIR"
cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ResumePad
GenericName=任务上下文恢复
Comment=任务切换时的上下文记录
Exec=${LAUNCHER}
Path=${ROOT}
Icon=${ICON}
Terminal=false
Categories=Office;Utility;
StartupNotify=true
StartupWMClass=ResumePad
X-GNOME-WMClass=ResumePad
EOF

command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo "已安装: $DESKTOP_FILE"
echo ""
echo "下一步：在应用菜单搜索 ResumePad，固定到 Dock（不要从 Edge 图标里启动）。"
echo "数据目录: ${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad/edge-profile"
