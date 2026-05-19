#!/usr/bin/env sh
# 安装 ResumePad 为独立桌面应用（固定目录 + 菜单项，类似 draw.io）。
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
INSTALL_APP="$ROOT/scripts/install-app.sh"

if [ "$1" = "--prefix" ] && [ -n "$2" ]; then
  shift
  exec sh "$INSTALL_APP" "$1"
fi

if [ -n "$1" ] && [ "$1" != "--help" ]; then
  exec sh "$INSTALL_APP" "$1"
fi

exec sh "$INSTALL_APP"
