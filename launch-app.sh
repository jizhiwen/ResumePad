#!/usr/bin/env sh
# Edge 应用模式启动 ResumePad（独立窗口 + Dock 与 Edge 分开）。
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
URL="file://${ROOT}/index.html?standalone=1"
WM_CLASS="${RESUMEPAD_WM_CLASS:-ResumePad}"
PROFILE="${XDG_CONFIG_HOME:-$HOME/.config}/ResumePad/edge-profile"

mkdir -p "$PROFILE"

export CHROME_DESKTOP=resumepad.desktop
export GTK_APPLICATION_ID=resumepad

run_edge() {
  edge_cmd=$1
  shift

  set -- \
    --user-data-dir="$PROFILE" \
    --app="$URL" \
    --class="$WM_CLASS" \
    --name=ResumePad \
    --password-store=basic

  if [ -n "${WAYLAND_DISPLAY:-}" ] && [ "${RESUMEPAD_USE_WAYLAND:-}" != 1 ]; then
    set -- "$@" --ozone-platform=x11
  fi

  exec "$edge_cmd" "$@"
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
