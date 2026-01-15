include $(TOPDIR)/rules.mk

PKG_NAME:=network-gcxy
PKG_VERSION:=0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/network-gcxy
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Auto Login Network Monitor For Xjie
  DEPENDS:=+curl +ip-full  # 自动安装所需的依赖
endef

define Build/Compile
endef

define Package/network-gcxy/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/network-gcxy.sh $(1)/usr/bin/network-gcxy.sh
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/network-gcxy.init $(1)/etc/init.d/network-gcxy
endef

$(eval $(call BuildPackage,network-gcxy))