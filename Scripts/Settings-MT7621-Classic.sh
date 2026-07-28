#!/bin/bash

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config

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

# 压缩 Xray-core 二进制，极限节省固件体积 (大约可节省 4MB-5MB 闪存空间)
XRAY_MAKEFILE=$(find ./feeds/ -type f -path "*/xray-core/Makefile" | head -n 1)
if [ -n "$XRAY_MAKEFILE" ] && [ -f "$XRAY_MAKEFILE" ]; then
	sed -i 's/\$(INSTALL_BIN) \$(PKG_INSTALL_DIR)\/usr\/bin\/main \$(1)\/usr\/bin\/xray/upx --lzma --best \$(PKG_INSTALL_DIR)\/usr\/bin\/main || true\n\t\$(INSTALL_BIN) \$(PKG_INSTALL_DIR)\/usr\/bin\/main \$(1)\/usr\/bin\/xray/g' $XRAY_MAKEFILE
fi

# 强制删除编译扫描缓存
rm -rf ./tmp
