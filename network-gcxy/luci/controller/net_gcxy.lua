module("luci.controller.net_gcxy", package.seeall)

function index()
    -- entry(路径, 对应的CBI模型, 菜单标题, 排序权重)
    entry({"admin", "network", "gcxy"}, cbi("net_gcxy"), _("Campus Network"), 10).dependent = true
end
