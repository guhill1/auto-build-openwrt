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

# =============================================================================
# 1. 【核心备份】先把调好的 .config 锁死，防止被接下来的操作改乱
[ -f .config ] && cp .config .config.bak

# =============================================================================
# 2. Fix Rust
# =============================================================================
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# =============================================================================
# 3. Fix MosDNS (sbwml 垂直打击版)
# =============================================================================
# 物理清理残留
rm -rf feeds/packages/net/mosdns
rm -rf package/luci-app-mosdns

# 垂直拉取：直接进 package 目录，避开 feeds 软链接冲突
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# =============================================================================
# 4. Fix SmartDNS (官方/指定源确权)
# =============================================================================
# 物理清理冲突包
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/packages/net/smartdns

# 重新扫码并安装 (仅针对 SmartDNS 所在的 feeds)
./scripts/feeds update -i
./scripts/feeds install -a

# =============================================================================
# 5. 【配置回填与索引建立】
# =============================================================================
# 把刚才锁死的配置原封不动拷回来
if [ -f .config.bak ]; then
    cp .config.bak .config
    echo "--- 已恢复原始配置清单 ---"
fi

# 【核心一步：建立 Mapping 索引】
# 不再用大量 echo，直接让系统把 .config 里的 y 开关与刚搞好的源码“锁死”
# 这一步会处理好 MosDNS 和 SmartDNS 的所有依赖
make oldconfig

# =========================================================
# 6.
# =========================================================
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
