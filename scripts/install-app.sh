#!/usr/bin/env sh
# 将 ResumePad 安装到固定目录（类似 draw.io 的 /opt/drawio）。
# 用法: install-app.sh [安装根目录]
#   默认: ~/.local/opt/resumepad
#   系统级: sudo install-app.sh /opt/resumepad
set -e

SRC="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PREFIX="${1:-${HOME}/.local/opt/resumepad}"
APP_DIR="$PREFIX/app"
LIB_DIR="$PREFIX/lib"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
BIN_DIR="${HOME}/.local/bin"
ICON_SCRIPT="$SRC/icons/install-icons.sh"

echo "正在安装 ResumePad 到: $PREFIX"

if ! command -v microsoft-edge >/dev/null 2>&1 && \
   ! command -v microsoft-edge-stable >/dev/null 2>&1 && \
   ! command -v msedge >/dev/null 2>&1 && \
   [ ! -x /opt/microsoft/msedge/msedge ]; then
  echo "未找到 Microsoft Edge，请先安装 Edge。"
  exit 1
fi

rm -rf "$PREFIX"
mkdir -p "$APP_DIR" "$LIB_DIR/scripts"

cp "$SRC/resumepad" "$PREFIX/resumepad"
cp "$SRC/lib/launch-app.sh" "$LIB_DIR/launch-app.sh"
cp "$SRC/index.html" "$SRC/manifest.webmanifest" "$APP_DIR/"
cp -r "$SRC/icons" "$APP_DIR/"
cp "$SRC/scripts/"*.py "$SRC/scripts/"*.sh "$LIB_DIR/scripts/" 2>/dev/null || true

chmod +x "$PREFIX/resumepad" "$LIB_DIR/launch-app.sh" \
  "$LIB_DIR/scripts/"*.sh 2>/dev/null || true

if [ ! -f "$APP_DIR/icons/icon-512.png" ] && [ -f "$APP_DIR/icons/generate-png.sh" ]; then
  sh "$APP_DIR/icons/generate-png.sh"
fi

if [ -f "$ICON_SCRIPT" ]; then
  ICON_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}"
  sh "$ICON_SCRIPT" || echo "  警告: 图标安装失败" >&2
fi

mkdir -p "$BIN_DIR"
ln -sfn "$PREFIX/resumepad" "$BIN_DIR/resumepad"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad"
PROFILE="${CONFIG_DIR}/edge-profile"
export RESUMEPAD_APP_DIR="$APP_DIR"
export RESUMEPAD_LIB="$LIB_DIR"
sh "$LIB_DIR/scripts/init-config.sh" "$APP_DIR" "$CONFIG_DIR"

APP_INDEX="${CONFIG_DIR}/app-root/index.html"
STARTUP_WM=$(python3 -c "import os; p=os.path.abspath('${APP_INDEX}'); print(p.lstrip('/').replace('/', '_'))")

ICON_NAME="resumepad"

mkdir -p "$DESKTOP_DIR"
cat >"$DESKTOP_DIR/resumepad.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ResumePad
GenericName=任务上下文恢复
Comment=任务切换时的上下文记录
Exec=${PREFIX}/resumepad %U
Icon=${ICON_NAME}
Terminal=false
Categories=Office;Utility;
StartupWMClass=${STARTUP_WM}
EOF

command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo ""
echo "安装完成（draw.io 风格）"
echo "  程序: ${PREFIX}/resumepad"
echo "  命令: resumepad  （~/.local/bin）"
echo "  桌面项: ${DESKTOP_DIR}/resumepad.desktop"
echo "  用户数据: ${CONFIG_DIR}"
echo "  卸载: ./uninstall-desktop-entry.sh"
echo ""
echo "请从应用菜单打开 ResumePad，并重新固定 Dock 图标。"
