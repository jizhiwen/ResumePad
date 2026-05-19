#!/bin/sh
# 安装 .deb 后移除旧版 Edge 脚本安装（~/.local/opt/resumepad），避免菜单仍指向 Edge。
set -e

remove_legacy_for_home() {
  home=$1
  [ -d "$home" ] || return 0
  rm -f "$home/.local/bin/resumepad"
  rm -rf "$home/.local/opt/resumepad"
  rm -f "$home/.local/share/applications/resumepad.desktop"
}

if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != root ]; then
  remove_legacy_for_home "$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

for home in /home/*; do
  remove_legacy_for_home "$home"
done

command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database /usr/local/share/applications 2>/dev/null || true
command -v update-desktop-database >/dev/null 2>&1 &&
  update-desktop-database /usr/share/applications 2>/dev/null || true
