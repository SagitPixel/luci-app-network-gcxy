include $(TOPDIR)/rules.mk

PKG_NAME:=network-gcxy
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/network-gcxy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Auto Login Network Monitor For Xjie
  DEPENDS:=+curl +ip-full +jsonfilter
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./files/* $(PKG_BUILD_DIR)/
	$(CP) ./luci/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
endef

define Package/network-gcxy/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/bin

	$(INSTALL_DATA) $(PKG_BUILD_DIR)/controller/net_gcxy.lua $(1)/usr/lib/lua/luci/controller/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/model/cbi/net_gcxy.lua $(1)/usr/lib/lua/luci/model/cbi/
	
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/network-gcxy.config $(1)/etc/config/network-gcxy
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/network-gcxy.init $(1)/etc/init.d/network-gcxy
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/network-gcxy.sh $(1)/usr/bin/network-gcxy.sh
endef

$(eval $(call BuildPackage,network-gcxy))