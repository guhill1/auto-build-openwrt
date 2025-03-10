#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify compile version
#sed -i 's/KERNEL_PATCHVER:=6.1/KERNEL_PATCHVER:=6.6/g' target/linux/x86/Makefile

build_date=$(date +'%Y-%m-%d')
sed -i "s/<%=pcdata(ver.distname)%> <%=pcdata(ver.distversion)%> /<%=pcdata(ver.distname)%> <%=pcdata(ver.distversion)%> guhill $build_date /g" package/lean/autocore/files/x86/index.htm
