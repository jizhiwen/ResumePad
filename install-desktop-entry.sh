#!/usr/bin/env sh
# 安装桌面项与图标。
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_FILE="$DESKTOP_DIR/resumepad.desktop"
LAUNCHER="$ROOT/launch-app.sh"
ICON_SCRIPT="$ROOT/icons/install-icons.sh"
WM_CLASS="${RESUMEPAD_WM_CLASS:-resumepad}"

edge_cmd() {
  if command -v microsoft-edge >/dev/null 2>&1; then echo microsoft-edge
  elif command -v microsoft-edge-stable >/dev/null 2>&1; then echo microsoft-edge-stable
  elif command -v msedge >/dev/null 2>&1; then echo msedge
  fi
}

echo "正在安装 ResumePad…"

if [ ! -f "$ROOT/icons/icon-512.png" ] && [ -f "$ROOT/icons/generate-png.sh" ]; then
  sh "$ROOT/icons/generate-png.sh"
fi

if ! edge=$(edge_cmd); then
  echo "未找到 Microsoft Edge，请先安装 Edge。"
  exit 1
fi

chmod +x "$LAUNCHER" "$ROOT/scripts/window-bounds.py" 2>/dev/null || true

if [ -f "$ICON_SCRIPT" ]; then
  chmod +x "$ICON_SCRIPT" 2>/dev/null || true
  sh "$ICON_SCRIPT" || echo "  警告: 部分图标未安装成功" >&2
fi

PIXMAP="${XDG_DATA_HOME:-$HOME/.local/share}/pixmaps/resumepad.png"
if [ -f "$PIXMAP" ]; then
  ICON_NAME="$PIXMAP"
elif [ -f "$ROOT/icons/icon-512.png" ]; then
  ICON_NAME="$ROOT/icons/icon-512.png"
else
  ICON_NAME="resumepad"
fi

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
Icon=${ICON_NAME}
Terminal=false
Categories=Office;Utility;
StartupNotify=true
StartupWMClass=${WM_CLASS}
EOF

command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo ""
echo "安装完成"
echo "  桌面项: $DESKTOP_FILE"
echo "  StartupWMClass: $WM_CLASS"
echo ""
echo "请取消 Dock 上旧的固定项，从应用菜单打开 ResumePad 后再固定到 Dock。"
echo "数据目录: ${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad/edge-profile"
