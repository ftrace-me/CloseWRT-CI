#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_FILE="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
#修改WIFI名称
sed -i "s/ImmortalWrt/$WRT_SSID/g" $WIFI_FILE
#修改5G频率后缀 (针对mtwifi.sh中 radio1 的处理)
sed -i "/radio1/,/ssid/s/ssid='$WRT_SSID'/ssid='$WRT_SSID-5G'/" $WIFI_FILE
#修改WIFI加密与密码
if [ -z "$WRT_WORD" ]; then
	sed -i "s/encryption=.*/encryption='none'/g" $WIFI_FILE
else
	sed -i "s/encryption=.*/encryption='sae-mixed'/g" $WIFI_FILE
	sed -i "/set wireless.default_\${dev}.encryption='sae-mixed'/a \\\t\t\t\t\t\set wireless.default_\${dev}.key='$WRT_WORD'" $WIFI_FILE
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

# 修复 tools/flex gettext version mismatch 导致编译失败的问题
sed -i 's/\$(eval \$(call HostBuild))//g' tools/flex/Makefile
cat << 'EOF' >> tools/flex/Makefile

define Host/Prepare
	$(call Host/Prepare/Default)
	sed -i '/check-macro-version:/{N;N;d;}' $(HOST_BUILD_DIR)/po/Makefile.in.in
	echo -e "\ncheck-macro-version:\n\t@true" >> $(HOST_BUILD_DIR)/po/Makefile.in.in
endef

$(eval $(call HostBuild))
EOF

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# 物理删除 feeds 和 package 中的 autocore 插件目录，防止其进行 any 编译与打包
rm -rf ./feeds/packages/package/emortal/autocore
rm -rf ./package/emortal/autocore

# 使用系统原生 Go 编译器
./scripts/feeds update -i
./scripts/feeds install -f golang

# 删除与 Go 不兼容的旧版 feeds 插件
rm -rf ./feeds/packages/net/v2ray-plugin

# 强制删除编译扫描缓存
rm -rf ./tmp
