#!/bin/bash

# Add PassWall feeds from kenzok8 (18.06 compatible)
echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> ../feeds.conf.default
echo "src-git small https://github.com/kenzok8/small" >> ../feeds.conf.default

# Replace Go toolchain with 24.x to support compiling modern xray-core on 18.06
rm -rf ../feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x ../feeds/packages/lang/golang

# Clone 18.06 compatible luci-theme-argon directly to package directory to guarantee precedence
rm -rf ../feeds/luci/themes/luci-theme-argon
rm -rf ../package/feeds/luci/luci-theme-argon
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git ../package/luci-theme-argon

# Update feeds first to pull repositories
cd ..
./scripts/feeds update -a

# Delete duplicate and incompatible xray/v2ray packages from official packages feed
rm -rf ./feeds/packages/net/xray-core
rm -rf ./feeds/packages/net/v2ray-core
rm -rf ./feeds/packages/net/v2ray-plugin
rm -rf ./feeds/packages/net/v2ray
rm -rf ./feeds/packages/net/sing-box

# Re-install all packages, forcing small and kenzo priority
./scripts/feeds install -a -f -p small
./scripts/feeds install -a -f -p kenzo
./scripts/feeds install -a
cd package
