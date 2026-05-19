#!/usr/bin/env sh
# Edge 应用模式启动 ResumePad（独立窗口 + Dock 与 Edge 分开）。
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
URL="file://${ROOT}/index.html?standalone=1"
PROFILE="${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad/edge-profile"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad"
BOUNDS_PY="$ROOT/scripts/window-bounds.py"
WM_CLASS="${RESUMEPAD_WM_CLASS:-resumepad}"
BG_COLOR="#fafafa"
WIN_W=960
WIN_H=500
WIN_X=80
WIN_Y=50

mkdir -p "$PROFILE" "$CONFIG_DIR"
export RESUMEPAD_INDEX_PATH="$ROOT/index.html"

if [ -f "$CONFIG_DIR/wm-class" ]; then
  saved=$(tr -d '\n' <"$CONFIG_DIR/wm-class")
  [ -n "$saved" ] && WM_CLASS=$saved
fi

if [ -f "$BOUNDS_PY" ]; then
  python3 "$BOUNDS_PY" prepare "$PROFILE" "$CONFIG_DIR" || true
  bounds=$(python3 "$BOUNDS_PY" read "$PROFILE" "$CONFIG_DIR" 2>/dev/null || true)
  theme=$(python3 "$BOUNDS_PY" theme "$PROFILE" "$CONFIG_DIR" 2>/dev/null || true)
  if [ -n "$bounds" ]; then
    eval "$(printf '%s' "$bounds" | python3 -c "
import json, sys
b = json.load(sys.stdin)
print(f'WIN_W={int(b[\"w\"])}; WIN_H={int(b[\"h\"])}; WIN_X={int(b[\"x\"])}; WIN_Y={int(b[\"y\"])}')
" 2>/dev/null)" || true
  fi
  if [ "$theme" = "dark" ]; then
    BG_COLOR="#0a0a0a"
  fi
fi

export CHROME_DESKTOP=resumepad.desktop
export GTK_APPLICATION_ID=resumepad

run_edge() {
  edge_cmd=$1
  shift

  set -- \
    --user-data-dir="$PROFILE" \
    --app="$URL" \
    --class="$WM_CLASS" \
    --name="$WM_CLASS" \
    --window-size="${WIN_W},${WIN_H}" \
    --window-position="${WIN_X},${WIN_Y}" \
    --background-color="$BG_COLOR" \
    --lang=zh-CN \
    --disable-features=TranslateUI,Translate,OfferTranslate,OfferTranslation \
    --disable-translate \
    --disable-translate-new-ux \
    --password-store=basic

  if [ -n "${WAYLAND_DISPLAY:-}" ] && [ "${RESUMEPAD_USE_WAYLAND:-}" != 1 ]; then
    set -- "$@" --ozone-platform=x11
  fi

  "$edge_cmd" "$@"
  status=$?

  if [ -f "$BOUNDS_PY" ]; then
    python3 "$BOUNDS_PY" save "$PROFILE" "$CONFIG_DIR" 2>/dev/null || true
  fi

  exit "$status"
}

if command -v microsoft-edge >/dev/null 2>&1; then
  run_edge microsoft-edge
elif command -v microsoft-edge-stable >/dev/null 2>&1; then
  run_edge microsoft-edge-stable
elif command -v msedge >/dev/null 2>&1; then
  run_edge msedge
fi

echo "未找到 Microsoft Edge。请安装 Edge，或直接打开："
echo "  $URL"
exit 1
