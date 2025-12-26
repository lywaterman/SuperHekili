#!/bin/bash

# Hekili 同步脚本
# 1. 在 Hekili 目录编译
# 2. 同步 Hekili → SuperHekili（排除 .git）

set -e

HEKILI_DIR="/Applications/World of Warcraft/_classic_titan_/Interface/AddOns/Hekili"
SUPERHEKILI_DIR="$HOME/Documents/Github/SuperHekili"

echo "=== 开始同步 Hekili → SuperHekili ==="

# 1. 编译
echo ""
echo "[1/2] 在 Hekili 目录编译 DruidFeral.simc..."
cd "$HEKILI_DIR"
luajit compile_and_update.lua "Wrath/APLs/DruidFeral.simc" "Wrath/Druid.lua" 11 "野性(黑科研)" "风雪"

# 2. 同步（排除 .git）
echo ""
echo "[2/2] 同步到 SuperHekili..."
rsync -av --exclude='.git' "$HEKILI_DIR/" "$SUPERHEKILI_DIR/"

echo ""
echo "=== 同步完成 ==="
