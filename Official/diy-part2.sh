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
# 5. 【配置回填与索引建立】
# =============================================================================
# 把刚才锁死的配置原封不动拷回来
if [ -f .config.bak ]; then
    cp .config.bak .config
    echo "--- 已恢复原始配置清单 ---"
fi

make defconfig

# =========================================================
# 6.
# =========================================================
build_date=$(date +'%Y-%m-%d')
sed -i -E "s/OPENWRT_RELEASE=.{1}%D %V %C.*/OPENWRT_RELEASE='%D %V %C guhill $build_date'/g" \
package/base-files/files/usr/lib/os-release
