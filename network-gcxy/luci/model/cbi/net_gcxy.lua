local fs = require "nixio.fs"

-- 定义 Map
m = Map("network-gcxy", "校园网自动认证 (GCXY)", "后台检测网络状态，断网自动尝试重连。")

-- ==================== 状态监控小节 ====================
s_status = m:section(TypedSection, "login", "当前状态")
s_status.anonymous = true

-- 1. 运行状态：通过检查进程是否存在来判断
status = s_status:option(DummyValue, "_status", "监控进程")
function status.cfgvalue(self, section)
    local enabled = m:get(section, "enabled")
    -- 实时检查脚本进程是否存在
    local is_running = luci.sys.call("pgrep -f network-gcxy.sh >/dev/null") == 0
    
    if enabled == "1" then
        return is_running and "🟢 正在监控中..." or "⚠️ 插件已启用但进程未启动"
    else
        return "⚪ 插件已禁用"
    end
end

-- 2. 最新动态：直接显示日志最后一行（更真实）
msg = s_status:option(DummyValue, "_last_msg", "最新动态")
function msg.cfgvalue(self, section)
    -- 获取最后一行非空日志
    local last_log = luci.sys.exec("tail -n 1 /var/log/network_gcxy.log 2>/dev/null | sed 's/\\[.*\\] //'")
    if not last_log or last_log == "" then
        return "尚无运行记录"
    end

    -- 简单的状态美化：如果包含“等待”，说明正在休眠
    if last_log:match("等待") then
        return "💤 " .. last_log
    elseif last_log:match("正常") then
        return "✅ " .. last_log
    elseif last_log:match("失败") or last_log:match("错误") then
        return "❌ " .. last_log
    else
        return "🔄 " .. last_log
    end
end

-- ==================== 配置管理小节 ====================
-- （此处保持你原有的配置管理小节代码不变）
-- ...

-- ==================== 快捷操作小节 ====================
-- 修正：按钮调用的参数需要与 .sh 脚本中的 case 分支匹配
s_cmd = m:section(TypedSection, "login", "快捷操作")
s_cmd.anonymous = true

btn_auth = s_cmd:option(Button, "_auth", "强制执行认证")
btn_auth.inputstyle = "apply"
function btn_auth.write(self, section)
    -- 你的脚本 case 匹配的是 "force"，而不是 "force_auth"
    luci.sys.exec("/usr/bin/network-gcxy.sh force &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "gcxy"))
end

btn_test = s_cmd:option(Button, "_test", "立即检测网络")
btn_test.inputstyle = "find"
function btn_test.write(self, section)
    -- 你的脚本 case 匹配的是 "test"，而不是 "test_now"
    luci.sys.exec("/usr/bin/network-gcxy.sh test &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "gcxy"))
end

return m