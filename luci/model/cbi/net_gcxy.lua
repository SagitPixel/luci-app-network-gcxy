local fs = require "nixio.fs"

m = Map("network-gcxy", "校园网自动认证 (GCXY)", "后台每2分钟检测一次网络，断网自动重启WAN并认证。")

-- 状态监控小节
s_status = m:section(TypedSection, "login", "当前状态")
s_status.anonymous = true

-- 1. 显示插件是否在运行
status = s_status:option(DummyValue, "_status", "运行状态")
function status.cfgvalue(self, section)
    local enabled = m:get(section, "enabled")
    if enabled == "1" then
        return "🟢 正在监控中..."
    else
        return "⚪ 插件已禁用"
    end
end

-- 2. 实时抓取日志最后一条关键信息
msg = s_status:option(DummyValue, "_last_msg", "最新动态")
function msg.cfgvalue(self, section)
    -- 从日志文件最后 5 行里找最近的一条记录
    local last_log = luci.sys.exec("tail -n 5 /var/log/network_gcxy.log 2>/dev/null")
    if not last_log or last_log == "" then
        return "尚无运行记录"
    end
    
    if last_log:match("成功访问") then return "✅ 网络连接正常"
    elseif last_log:match("认证执行完毕") then return "🚀 认证请求已发送"
    elseif last_log:match("警告") then return "⚠️ 无法获取MAC地址"
    elseif last_log:match("错误") then return "❌ 获取IP失败"
    elseif last_log:match("网络断开") then return "🔄 正在尝试修复网络..."
    else return "⏳ 正在检测中..." end
end

-- 配置管理小节
s = m:section(TypedSection, "login", "参数设置")
s.anonymous = true

-- 3. 启用开关
e = s:option(Flag, "enabled", "启用脚本")
e.rmempty = false

-- 4. 手机号输入
p = s:option(Value, "phone", "认证手机号")
p.datatype = "phonedigit"
p.description = "输入后系统会自动拼接为 g+手机号"

-- 5. 日志查看器
t = s:option(TextValue, "logview", "详细运行日志")
t.readonly = true
t.rows = 12
function t.cfgvalue()
    return fs.readfile("/var/log/network_gcxy.log") or "等待日志生成..."
end

-- 6. 按钮：清理日志
btn = s:option(Button, "_clear", "清理日志内容")
btn.inputstyle = "remove"
function btn.write(self, section)
    luci.sys.exec("> /var/log/network_gcxy.log")
end

return m

-- 先定义一个执行动作的小节
s_cmd = m:section(TypedSection, "login", "快捷操作")
s_cmd.anonymous = true

-- 按钮 1：手动强制认证
btn_auth = s_cmd:option(Button, "_auth", "强制执行认证")
btn_auth.inputstyle = "apply"
function btn_auth.write(self, section)
    -- 调用脚本，并传入一个特殊参数让它知道是强制认证（或者直接执行认证部分的逻辑）
    -- 这里最简单的方法是直接运行你的脚本文件
    luci.sys.exec("/usr/bin/network-gcxy.sh force_auth &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "network_gcxy"))
end

-- 按钮 2：重连 WAN 口
btn_wan = s_cmd:option(Button, "_wan", "重连 WAN 接口")
btn_wan.inputstyle = "reload"
function btn_wan.write(self, section)
    luci.sys.exec("/sbin/ifdown wan && sleep 2 && /sbin/ifup wan")
end

-- 按钮 3：立即检测网络
btn_test = s_cmd:option(Button, "_test", "立即检测网络")
btn_test.inputstyle = "find"
function btn_test.write(self, section)
    -- 执行一次简单的 ping 或 curl 检测，结果会写入日志
    luci.sys.exec("/usr/bin/network-gcxy.sh test_now &")
end