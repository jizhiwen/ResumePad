#!/usr/bin/env sh
# 兼容旧用法：转调 resumepad（开发目录或已安装目录均可）。
ROOT="$(CDPATH= cd -- "$(dirname -- "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
exec "$ROOT/resumepad" "$@"
