#!/bin/bash

# Add PassWall feeds
echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> ../feeds.conf.default
echo "src-git passwall https://github.com/xiaorouji/openwrt-passwall.git;main" >> ../feeds.conf.default

# Replace Go toolchain with 24.x to support compiling modern xray-core on 18.06
rm -rf ../feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x ../feeds/packages/lang/golang

# Replace luci-theme-argon with 18.06 compatible branch
rm -rf ../feeds/luci/themes/luci-theme-argon
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git ../feeds/luci/themes/luci-theme-argon

# Update and install the feeds
cd ..
./scripts/feeds update passwall passwall_packages
./scripts/feeds install -a -f -p passwall_packages
./scripts/feeds install -a -f -p passwall
cd package
