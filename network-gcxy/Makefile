include $(TOPDIR)/rules.mk

PKG_NAME:=network-gcxy
PKG_VERSION:=1.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/network-gcxy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Auto Login Network Monitor For Xjie Dormitory
  PKG_ARCH:=all
  # 确保包含 jsonfilter 以便脚本能解析 ubus 输出的 IP 地址
  DEPENDS:=+curl +ip-full +jsonfilter
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	# 确保文件被正确复制到编译目录
	$(CP) ./files/* $(PKG_BUILD_DIR)/
	$(CP) ./luci/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	# 脚本类插件无需编译
endef

define Package/network-gcxy/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/bin

	# 安装 Lua 控制器与模型
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/controller/net_gcxy.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/model/cbi/net_gcxy.lua $(1)/usr/lib/lua/luci/model/cbi/
	
	# 安装 UCI 配置文件
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/network-gcxy.config $(1)/etc/config/network-gcxy
	
	# 安装启动服务脚本与核心监控脚本 (赋予 755 权限)
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/network-gcxy.init $(1)/etc/init.d/network-gcxy
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/network-gcxy.sh $(1)/usr/bin/network-gcxy.sh
endef

$(eval $(call BuildPackage,network-gcxy))