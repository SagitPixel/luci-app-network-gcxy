module("luci.controller.network_gcxy", package.seeall)

function index()
    -- entry(路径, 类型, 标题, 排序)
    entry({"admin", "network", "network_gcxy"}, cbi("network_gcxy"), "校园网认证", 100).dependent = true
end