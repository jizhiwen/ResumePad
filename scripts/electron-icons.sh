#!/usr/bin/env sh
# 为 electron-builder 准备 build/icon.png（512×512）
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
BUILD="$ROOT/build"
mkdir -p "$BUILD"

if [ ! -f "$ROOT/icons/icon-512.png" ]; then
  sh "$ROOT/icons/generate-png.sh"
fi

if [ ! -f "$ROOT/icons/icon-512.png" ]; then
  echo "缺少 icons/icon-512.png。请安装 rsvg-convert 或 ImageMagick，或: pip install cairosvg" >&2
  exit 1
fi

cp "$ROOT/icons/icon-512.png" "$BUILD/icon.png"
echo "electron-builder 图标: $BUILD/icon.png"
