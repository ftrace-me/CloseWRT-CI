#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称 of 软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done
	
	# 删除本地当前目录可能存在的软件包仓库文件夹，防止 git clone 失败
	if [ -d "$REPO_NAME" ]; then
		rm -rf "$REPO_NAME"
		echo "Delete local directory: $REPO_NAME"
	fi

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

# 升级 Go 工具链至 1.26.x，满足最新 xray-core / sing-box (requires go >= 1.26) 的编译要求
rm -rf ../feeds/packages/lang/golang
git clone --depth=1 --single-branch --branch 26.x https://github.com/sbwml/packages_lang_golang.git ../feeds/packages/lang/golang

# 添加 PassWall 软件源
echo "src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main" >> ../feeds.conf.default
echo "src-git passwall https://github.com/Openwrt-Passwall/openwrt-passwall.git;main" >> ../feeds.conf.default

# 更新并安装 feeds 中的 PassWall
cd ..
./scripts/feeds update -a

# 删除官方软件源中可能冲突和不兼容的老旧包（hanwckf 21.02 源自带的版本过旧）
rm -rf ./feeds/luci/applications/luci-app-passwall
rm -rf ./feeds/packages/net/chinadns-ng
rm -rf ./feeds/packages/net/dns2socks
rm -rf ./feeds/packages/net/dns2tcp
rm -rf ./feeds/packages/net/ipt2socks
rm -rf ./feeds/packages/net/microsocks
rm -rf ./feeds/packages/net/tcping
rm -rf ./feeds/packages/net/xray-core
rm -rf ./feeds/packages/net/v2ray-core
rm -rf ./feeds/packages/net/v2ray-plugin
rm -rf ./feeds/packages/net/v2ray

./scripts/feeds install -a -f -p passwall_packages
./scripts/feeds install -a -f -p passwall
./scripts/feeds install -a
cd package

# 获取更轻量的 luci-theme-design 主题替代 argon
git clone --depth=1 --single-branch --branch master https://github.com/gSpotx2f/luci-theme-design.git

# 启用及拉取的第三方包
UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "luci-app-timewol luci-app-wolplus"
