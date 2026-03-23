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
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/packages/net/smartdns

# 3. 确权：强行重新全局扫码
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 精确删除并强行确权
# 删掉 "# ...smartdns " (带空格的注释行) 和 "smartdns=" (赋值行)
sed -i '/# CONFIG_PACKAGE_smartdns /d; /CONFIG_PACKAGE_smartdns=/d' .config
echo "CONFIG_PACKAGE_smartdns=y" >> .config

sed -i '/# CONFIG_PACKAGE_luci-app-smartdns /d; /CONFIG_PACKAGE_luci-app-smartdns=/d' .config
echo "CONFIG_PACKAGE_luci-app-smartdns=y" >> .config
# ---------------------------------------------------------
# 5. MosDNS 状态显示补丁

MOSDNS_CONTROLLER="feeds/small/luci-app-mosdns/luasrc/controller/mosdns.lua"
[ -f "$MOSDNS_CONTROLLER" ] && sed -i 's/pgrep -x mosdns/pgrep -f mosdns/g' "$MOSDNS_CONTROLLER"

# 6. 通用自动化地鼠修复函数 (增强兼容性)
# ---------------------------------------------------------
set -x  # 开启 Shell 执行追踪

fix_pkg_hash_auto() {
    local pkg_path=$1
    local pkg_name=$2

    echo "------------------------------------------"
    echo "🎯 [DEBUG] Starting fix for: $pkg_name"
    echo "📂 [DEBUG] Expected Path: $pkg_path"

    # 1. 检查目录是否存在 (CI 里的路径经常带 feeds/xxx)
    if [ ! -d "$pkg_path" ]; then
        echo "⚠️ [DEBUG] Directory $pkg_path not found! Trying to find it..."
        pkg_path=$(find . -name "$pkg_name" -type d -not -path "*/.*" | head -n 1)
        echo "🔍 [DEBUG] Real path found: $pkg_path"
    fi

    [ -f "$pkg_path/Makefile" ] || { echo "❌ [DEBUG] Makefile not found in $pkg_path"; return 0; }

    # 2. 提取 Hash
    local expected_hash=$(grep -E "PKG_(MIRROR_)?HASH:=" "$pkg_path/Makefile" | cut -d'=' -f2 | tr -d ' \t')
    echo "🔎 [DEBUG] Hash in Makefile: $expected_hash"
    
    [ -z "$expected_hash" ] && { echo "⚠️ [DEBUG] No PKG_HASH found in Makefile"; return 0; }

    # 3. 预下载 (关键：去掉静默，开启 V=s)
    echo "🚀 [DEBUG] Running: make $pkg_path/download V=s"
    # 这里不重定向错误，让报错直接喷在 CI 日志里
    make "$pkg_path/download" V=s 

    # 4. 检查 dl 目录是否存在且有内容
    echo "📂 [DEBUG] Listing dl/ directory for '$pkg_name':"
    ls -lh dl/ | grep -i "$pkg_name" || echo "⚠️ [DEBUG] No file found in dl/ matching $pkg_name"

    local real_file=$(ls -t dl/${pkg_name}* 2>/dev/null | head -n 1)

    if [ -n "$real_file" ] && [ -f "$real_file" ]; then
        echo "📄 [DEBUG] Found downloaded file: $real_file"
        
        # 5. 计算真实 Hash
        local got_hash=$(sha256sum "$real_file" | cut -d' ' -f1)
        echo "🧮 [DEBUG] Calculated Hash: $got_hash"

        # 6. 如果不一致，执行替换
        if [ "$expected_hash" != "$got_hash" ]; then
            sed -i "s/$expected_hash/$got_hash/g" "$pkg_path/Makefile"
            echo "✅ [SUCCESS] Fixed $pkg_name: $expected_hash -> $got_hash"
            # 二次验证
            echo "📝 [DEBUG] Makefile content after sed:"
            grep "HASH:=" "$pkg_path/Makefile"
        else
            echo "⭐ [DEBUG] $pkg_name hash is already correct."
        fi
    else
        echo "❌ [DEBUG] Critical Error: Could not find any downloaded file for $pkg_name"
        echo "💡 [TIP] This usually means 'make download' failed due to missing tools (like ninja/cmake)."
		exit 1
    fi
}

# --- 执行调用 ---
fix_pkg_hash_auto "package/system/opkg" "opkg"
fix_pkg_hash_auto "package/network/utils/fullconenat-nft" "fullconenat-nft"

set +x
# ---------------------------------------------------------
# 7.
# ---------------------------------------------------------
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
