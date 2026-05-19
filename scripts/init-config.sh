#!/usr/bin/env sh
# 初始化 ~/.config/ResumePad（默认 window-bounds、app-root 链接、Edge 配置目录）。
# 用法: init-config.sh <app目录> [config-dir]
APP_DIR=$1
CONFIG_DIR=${2:-${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad}
PROFILE="${CONFIG_DIR}/edge-profile"
LIB="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
[ -d "$LIB/scripts" ] || LIB="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
SETUP_LINK="$LIB/scripts/setup-app-link.sh"
[ -f "$SETUP_LINK" ] || SETUP_LINK="$(dirname -- "$0")/setup-app-link.sh"
BOUNDS_PY="$(dirname -- "$0")/window-bounds.py"

if [ -z "$APP_DIR" ] || [ ! -f "$APP_DIR/index.html" ]; then
  echo "init-config.sh: 无效的应用目录" >&2
  exit 1
fi

mkdir -p "$CONFIG_DIR" "$PROFILE"
if [ -f "$SETUP_LINK" ]; then
  sh "$SETUP_LINK" "$APP_DIR" "$CONFIG_DIR"
fi

export RESUMEPAD_APP_INDEX="${CONFIG_DIR}/app-root/index.html"
export RESUMEPAD_INDEX_PATH="${APP_DIR}/index.html"
export RESUMEPAD_CONFIG_DIR="$CONFIG_DIR"

python3 "$BOUNDS_PY" init "$PROFILE" "$CONFIG_DIR"
