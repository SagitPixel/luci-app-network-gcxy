module("luci.controller.net_gcxy", package.seeall)

function index()
    entry({"admin", "network", "gcxy"}, cbi("net_gcxy"), _("校园网认证"), 10).dependent = true
end
