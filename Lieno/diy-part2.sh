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

# 1. 自动定位 Rust 的 Makefile 并关闭 CI LLVM 下载
# ---------------------------------------------------------
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# 2. 物理清障：干掉冲突包 (SmartDNS & Nikki)
# ---------------------------------------------------------
# 干掉官方版 SmartDNS，确权给 Kenzo/Small
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/packages/net/smartdns
# 顺便干掉那个会导致 out of sync 的 Nikki (物理超度)
rm -rf $(find feeds -name "luci-app-nikki" -type d)
rm -rf $(find feeds -name "nikki" -type d)

# 3. 重新关联 feeds (确保上面的删除生效)
# ---------------------------------------------------------
./scripts/feeds update -i
./scripts/feeds install -a

# 4. MosDNS 状态显示补丁
# ---------------------------------------------------------
MOSDNS_CONTROLLER="feeds/small/luci-app-mosdns/luasrc/controller/mosdns.lua"
[ -f "$MOSDNS_CONTROLLER" ] && sed -i 's/pgrep -x mosdns/pgrep -f mosdns/g' "$MOSDNS_CONTROLLER"

# 5. 通用自动化地鼠修复函数 (增强兼容性)
# ---------------------------------------------------------
fix_pkg_hash_auto() {
    local pkg_path=$1
    local pkg_name=$2
    [ -f "$pkg_path/Makefile" ] || return 0

    # 同时匹配 PKG_HASH 和 PKG_MIRROR_HASH
    local hash_line=$(grep -E "PKG_.*HASH:=" "$pkg_path/Makefile")
    local expected_hash=$(echo "$hash_line" | cut -d'=' -f2 | tr -d ' \t')
    [ -z "$expected_hash" ] && return 0

    echo "🔍 Checking $pkg_name..."
    make "$pkg_path/download" V=s > /dev/null 2>&1

    # 保护减号，精准抓取 dl 目录下的文件
    local real_file=$(ls -t dl/${pkg_name}* 2>/dev/null | head -n 1)

    if [ -f "$real_file" ]; then
        local got_hash=$(sha256sum "$real_file" | cut -d' ' -f1)
        if [ "$expected_hash" != "$got_hash" ]; then
            # 使用分隔符 | 防止路径中可能存在的斜杠干扰
            sed -i "s|$expected_hash|$got_hash|g" "$pkg_path/Makefile"
            echo "✅ Fixed $pkg_name: $got_hash"
        fi
    fi
}

fix_pkg_hash_auto "package/system/opkg" "opkg"
fix_pkg_hash_auto "package/network/utils/fullconenat-nft" "fullconenat-nft"

# 6.
# ---------------------------------------------------------
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
