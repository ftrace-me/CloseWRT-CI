#!/bin/bash

# Add PassWall feeds from kenzok8 (18.06 compatible LuCI) and official PassWall packages (for compilable binaries)
echo "src-git kenzo https://github.com/kenzok8/openwrt-packages" >> ../feeds.conf.default
echo "src-git small https://github.com/kenzok8/small" >> ../feeds.conf.default
echo "src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main" >> ../feeds.conf.default

# Replace Go toolchain with 26.x to support compiling modern xray-core on 18.06 (requires Go >= 1.26)
rm -rf ../feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x ../feeds/packages/lang/golang

# Clone 18.06 compatible luci-theme-argon directly to package directory to guarantee precedence
rm -rf ../feeds/luci/themes/luci-theme-argon
rm -rf ../package/feeds/luci/luci-theme-argon
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git ../package/luci-theme-argon

# Update feeds first to pull repositories
cd ..
./scripts/feeds update -a

# Delete duplicate and incompatible xray/v2ray packages from official packages feed AND small feed
rm -rf ./feeds/packages/net/xray-core
rm -rf ./feeds/packages/net/v2ray-core
rm -rf ./feeds/packages/net/v2ray-plugin
rm -rf ./feeds/packages/net/v2ray
rm -rf ./feeds/packages/net/sing-box

rm -rf ./feeds/small/xray-core
rm -rf ./feeds/small/v2ray-core
rm -rf ./feeds/small/v2ray-plugin
rm -rf ./feeds/small/v2ray
rm -rf ./feeds/small/sing-box

# Re-install all packages, forcing passwall_packages priority for binary cores, and small/kenzo for others
./scripts/feeds install -a -f -p passwall_packages
./scripts/feeds install -a -f -p small
./scripts/feeds install -a -f -p kenzo
./scripts/feeds install -a
cd package
