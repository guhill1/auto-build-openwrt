#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# Copyright (c) 2021-2026 guhill <https://github.com/guhill1>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# =========================================================
# 1. 物理清障：移除 ImmortalWrt 内置的 MosDNS (防止源冲突)
# =========================================================
# 在 CI 环境中，当前目录已是源码根目录，直接删除即可
rm -rf feeds/packages/net/mosdns

# 刷新索引并确权给你自定义源里的 MosDNS
./scripts/feeds update -i
./scripts/feeds install -a

# 精准定位这行并替换为启用状态
sed -i 's/# CONFIG_PACKAGE_mosdns is not set/CONFIG_PACKAGE_mosdns=y/g' .config
# 如果 sed 没匹配到（比如文件中根本没这一行），就直接追加到末尾
grep -q "CONFIG_PACKAGE_mosdns=y" .config || echo "CONFIG_PACKAGE_mosdns=y" >> .config
# =========================================================
# 2. 编译加速：Rust LLVM 离线补丁
# =========================================================
# 解决编译 Rust 插件时下载巨大 CI LLVM 导致的超时问题
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# =========================================================
# 3.
# =========================================================
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
