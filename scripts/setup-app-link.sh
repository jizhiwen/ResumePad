#!/usr/bin/env sh
# 在配置目录创建 app-root -> 仓库，供旧版固定项 / Edge 配置中的稳定 file:// 路径。
ROOT=$1
CONFIG_DIR=$2
APP_LINK="${CONFIG_DIR}/app-root"
mkdir -p "$CONFIG_DIR"
ln -sfn "$ROOT" "$APP_LINK"
