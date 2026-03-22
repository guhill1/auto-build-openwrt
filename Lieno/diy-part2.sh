#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
# Copyright (c) 2021-2026 guhill <https://github.com/guhill1>
#
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 1. 自动定位 Rust 的 Makefile 并关闭 CI LLVM 下载
# ---------------------------------------------------------
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# 2. 物理清障：仅干掉 SmartDNS 官方版 (确权给 Kenzo)
# ---------------------------------------------------------
# 注意：这里不删除 mosdns，只针对 smartdns 进行物理清障
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/packages/net/smartdns

# 3. 确权：刷新索引并安装 (让编译器识别到 SmartDNS 已切到 Kenzo)
# ---------------------------------------------------------
./scripts/feeds update -i
./scripts/feeds install -a

# 4. MosDNS 状态显示补丁 (针对 feeds/small 路径执行精准修改)
# ---------------------------------------------------------
MOSDNS_CONTROLLER="feeds/small/luci-app-mosdns/luasrc/controller/mosdns.lua"
if [ -f "$MOSDNS_CONTROLLER" ]; then
    echo "Applying MosDNS pgrep -f patch..."
    # 将精确匹配 -x 改为全路径匹配 -f，解决 i5 固件下带参数进程不显示的问题
    sed -i 's/pgrep -x mosdns/pgrep -f mosdns/g' "$MOSDNS_CONTROLLER"
fi

# 5. 自定义固件版本标识
# ---------------------------------------------------------
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
