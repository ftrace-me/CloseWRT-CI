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

# 启用及拉取的第三方包
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main" "" "mihomo-meta mihomo-alpha mihomo"
rm -rf ./OpenWrt-nikki/mihomo-alpha
UPDATE_PACKAGE "daed" "QiuSimons/luci-app-daed" "kix"
sed -i 's/GOEXPERIMENT=newinliner,simd/GOEXPERIMENT=newinliner/g' ./luci-app-daed/daed/Makefile
UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "luci-app-timewol luci-app-wolplus"
