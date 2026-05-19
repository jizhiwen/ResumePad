#!/usr/bin/env sh
# 启动 Edge 应用模式（由 resumepad 调用；勿直接运行）。
APP_DIR="${RESUMEPAD_APP_DIR:?}"
LIB="${RESUMEPAD_LIB:?}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad"
PROFILE="${CONFIG_DIR}/edge-profile"
INIT_CONFIG="$LIB/scripts/init-config.sh"
APP_URL="file://${APP_DIR}/index.html?standalone=1"
BOUNDS_PY="$LIB/scripts/window-bounds.py"
BOUNDS_WM="$LIB/scripts/bounds-wm.py"
EDGE_WM_CLASS="${RESUMEPAD_EDGE_WM_CLASS:-resumepad}"
BG_COLOR="#fafafa"
WIN_W=960
WIN_H=500
WIN_X=80
WIN_Y=50
_USE_WM=1

if [ -f "$INIT_CONFIG" ]; then
  sh "$INIT_CONFIG" "$APP_DIR" "$CONFIG_DIR"
else
  mkdir -p "$PROFILE" "$CONFIG_DIR"
  [ -f "$BOUNDS_PY" ] && python3 "$BOUNDS_PY" init "$PROFILE" "$CONFIG_DIR"
fi

_edge_pid=
_poller_pid=

_save_bounds() {
  if [ -f "$BOUNDS_WM" ] && [ "$_USE_WM" = 1 ]; then
    python3 "$BOUNDS_WM" poll "$CONFIG_DIR" 2>/dev/null && return 0
  fi
  if [ -f "$CONFIG_DIR/window-bounds.json" ] && python3 -c "
import json, sys
p=sys.argv[1]
raw=open(p).read().strip()
for part in raw.split('{'):
    if not part.strip(): continue
    try:
        o=json.loads('{'+part if not part.startswith('{') else part)
        int(o['w']); int(o['h']); sys.exit(0)
    except: pass
sys.exit(1)
" "$CONFIG_DIR/window-bounds.json" 2>/dev/null; then
    return 0
  fi
  [ -f "$BOUNDS_PY" ] && python3 "$BOUNDS_PY" save "$PROFILE" "$CONFIG_DIR" 2>/dev/null || true
}

_cleanup() {
  if [ -n "$_poller_pid" ]; then
    kill "$_poller_pid" 2>/dev/null || true
    wait "$_poller_pid" 2>/dev/null || true
    _poller_pid=
  fi
  _save_bounds
}
trap _cleanup EXIT INT TERM

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

if [ -x /opt/microsoft/msedge/msedge ]; then
  EDGE=/opt/microsoft/msedge/msedge
elif command -v microsoft-edge >/dev/null 2>&1; then
  EDGE=microsoft-edge
elif command -v microsoft-edge-stable >/dev/null 2>&1; then
  EDGE=microsoft-edge-stable
elif command -v msedge >/dev/null 2>&1; then
  EDGE=msedge
else
  echo "未找到 Microsoft Edge。"
  exit 1
fi

if ! command -v xwininfo >/dev/null 2>&1; then
  echo "提示: 未安装 xwininfo，窗口大小记忆可能受限。可执行: sudo apt install x11-utils" >&2
  _USE_WM=0
fi

set -- "$EDGE" \
  --user-data-dir="$PROFILE" \
  --app="$APP_URL" \
  --class="$EDGE_WM_CLASS" \
  --name="$EDGE_WM_CLASS" \
  --window-size="${WIN_W},${WIN_H}" \
  --window-position="${WIN_X},${WIN_Y}" \
  --background-color="$BG_COLOR" \
  --disable-background-mode \
  --lang=zh-CN \
  --disable-features=TranslateUI,Translate,OfferTranslate,OfferTranslation \
  --disable-translate \
  --disable-translate-new-ux \
  --password-store=basic

if [ -n "${WAYLAND_DISPLAY:-}" ] && [ "${RESUMEPAD_USE_WAYLAND:-}" != 1 ]; then
  set -- "$@" --ozone-platform=x11
fi

export CHROME_DESKTOP=resumepad.desktop
env CHROME_DESKTOP=resumepad.desktop "$@" &
_edge_pid=$!

if [ -f "$BOUNDS_WM" ] && [ "$_USE_WM" = 1 ]; then
  (
    sleep 1
    while kill -0 "$_edge_pid" 2>/dev/null; do
      python3 "$BOUNDS_WM" poll "$CONFIG_DIR" 2>/dev/null || true
      sleep 1
    done
  ) &
  _poller_pid=$!
fi

wait "$_edge_pid"
status=$?
exit "$status"
