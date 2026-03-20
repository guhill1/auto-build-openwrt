#!/bin/bash
#
# Copyright (c) 2019-2021 P3TERX <https://p3terx.com>
# Modified by guhill1 2022-2026
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# https://github.com/guhill1/auto-build-openwrt/
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify compile version
#sed -i 's/KERNEL_PATCHVER:=6.1/KERNEL_PATCHVER:=6.6/g' target/linux/x86/Makefile

build_date=$(date +'%Y-%m-%d')
target_js="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"

if [ -f "$target_js" ]; then
    sed -i "s/ + ' \[Guhill .*\]'//g" "$target_js"
    sed -i "s/boardinfo.release.description/boardinfo.release.description + ' [Guhill $build_date]'/g" "$target_js"
fi

[ -f package/lean/autocore/files/x86/autocore ] && sed -i '/index.htm/s/^/#/' package/lean/autocore/files/x86/autocore

