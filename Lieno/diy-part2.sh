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
set -x  # 开启调试追踪

echo "Checking environment..."
# 暴力修复 opkg
find package -name "Makefile" | grep "system/opkg/Makefile" | xargs sed -i 's/dbe5cb21e881d60733587cad22e01aab52ab5261b5f21003d32d06ff88442add/41fb2c79ce6014e28f7dd0cd8c65efe803986278f2587d1d4681883d8847d87c/g'

# 暴力修复 fullconenat-nft (兼容 PKG_MIRROR_HASH)
find package -name "Makefile" | grep "fullconenat-nft/Makefile" | xargs sed -i 's/6ea91089b9350df186961ac7a90200cc42083a2d29bb78f433a7279a25b76c2a/84d54b5e6091148c31d4eddff2f8ead763c9ef318fdf35098a6f9cea9a29b7c8/g'

# 验证环节：如果 grep 没输出，说明 sed 没改成功
echo "🔍 VERIFYING PATCHES..."
grep -r "41fb2c79" package/system/opkg/Makefile
grep -r "84d54b5e" package/network/utils/fullconenat-nft/Makefile

set +x  # 关闭调试，回到正常输出

# 6.
# ---------------------------------------------------------
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
