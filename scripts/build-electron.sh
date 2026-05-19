#!/usr/bin/env sh
# 构建 Electron 安装包（Linux AppImage/deb + Windows nsis/portable）
# 需要 Node.js >= 18（系统 apt 自带的 nodejs 12 无法安装 Electron 33）
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

node_major() {
  "$1" -e 'process.stdout.write(String(+process.version.slice(1).split(".")[0]))' 2>/dev/null
}

find_node18() {
  _candidate=""
  for _c in \
    "${NODE:-}" \
    "$HOME/.nvm/versions/node/"*/bin/node \
    /usr/local/bin/node \
    /usr/bin/node \
    "$(command -v node 2>/dev/null || true)"
  do
    [ -n "$_c" ] || continue
    [ -x "$_c" ] || continue
    _maj=$(node_major "$_c" || echo 0)
    [ "$_maj" -ge 18 ] 2>/dev/null || continue
    _candidate=$_c
    break
  done
  printf '%s' "$_candidate"
}

NODE_BIN=$(find_node18)
if [ -z "$NODE_BIN" ]; then
  echo "错误: 需要 Node.js 18 或更高版本（当前系统 node 过旧，无法安装 Electron）。" >&2
  echo "" >&2
  echo "Ubuntu / Debian 推荐安装 Node 20 LTS：" >&2
  echo "  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -" >&2
  echo "  sudo apt-get install -y nodejs" >&2
  echo "" >&2
  echo "或使用 nvm：" >&2
  echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash" >&2
  echo "  nvm install 20 && nvm use 20" >&2
  exit 1
fi

NODE_DIR=$(CDPATH= cd -- "$(dirname -- "$NODE_BIN")" && pwd)
export PATH="$NODE_DIR:$PATH"

# 优先使用与 Node 同目录的 npm（避免 /usr/bin/npm 绑定旧 node 12）
if [ -x "$NODE_DIR/npm" ]; then
  NPM="$NODE_DIR/npm"
elif [ -x "$NODE_DIR/npx" ]; then
  NPM="$NODE_DIR/npm"
else
  NPM=$(command -v npm 2>/dev/null || true)
fi

if [ -z "$NPM" ] || [ ! -x "$NPM" ]; then
  echo "错误: 未找到 npm。请与 Node 20 一并安装（见上方 nodesource 说明）。" >&2
  exit 1
fi

echo "Node: $($NODE_BIN -v)  npm: $($NPM -v 2>/dev/null || echo unknown)"

# 若曾用旧 Node 安装失败，先清理
if [ -d node_modules/electron ] && ! "$NODE_BIN" -e "require('electron/package.json'); process.exit(0)" 2>/dev/null; then
  echo "清理旧的 node_modules（此前 Node 版本不兼容）…"
  rm -rf node_modules package-lock.json
fi

deps_ok() {
  [ -x node_modules/.bin/electron-builder ] \
    && [ -f node_modules/electron-builder/package.json ] \
    && "$NODE_BIN" -e "require('electron/package.json')" 2>/dev/null
}

"$NPM" install

if ! deps_ok; then
  echo "依赖不完整（常见于安装中断或 node_modules 损坏），正在重新安装…" >&2
  rm -rf node_modules package-lock.json
  "$NPM" install
fi

if ! deps_ok; then
  echo "错误: electron / electron-builder 仍未正确安装。" >&2
  echo "请手动执行: rm -rf node_modules package-lock.json && npm install" >&2
  exit 1
fi

case "${1:-all}" in
  linux) "$NPM" run dist:linux ;;
  win|windows) "$NPM" run dist:win ;;
  *) "$NPM" run dist ;;
esac

echo ""
echo "输出目录: $ROOT/dist/"
