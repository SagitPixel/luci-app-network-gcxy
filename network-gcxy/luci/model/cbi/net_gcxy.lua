local fs = require "nixio.fs"

-- 定义 Map
m = Map("network-gcxy", "新疆工程学院宿舍网络自动认证", "后台检测网络状态，断网自动尝试重连。")

-- ==================== 状态监控小节 ====================
s_status = m:section(TypedSection, "login", "当前状态")
s_status.anonymous = true

-- 1. 显示插件是否运行
status = s_status:option(DummyValue, "_status", "运行状态")
function status.cfgvalue(self, section)
    local s = luci.sys.exec("cat /tmp/net_gcxy_status 2>/dev/null")
    if s and s ~= "" then
        return "🟢 " .. s
    else
        return "⚪ 插件未启动"
    end
end

-- 2. 实时抓取最新动态
msg = s_status:option(DummyValue, "_last_msg", "最新动态")
function msg.cfgvalue(self, section)
    -- 读取 /tmp/net_gcxy_action 里的内容
    local status_action = luci.sys.exec("cat /tmp/net_gcxy_action 2>/dev/null")
    if not status_action or status_action == "" then
        return "⏳ 等待脚本初始化..."
    end
    return "⏳ " .. status_action
end

-- ==================== 配置管理小节 ====================
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
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "gcxy"))
end

-- ==================== 快捷操作小节 ====================
s_cmd = m:section(TypedSection, "login", "快捷操作")
s_cmd.anonymous = true

-- 按钮 1：手动强制认证
btn_auth = s_cmd:option(Button, "_auth", "强制执行认证")
btn_auth.inputstyle = "apply"
function btn_auth.write(self, section)
    luci.sys.exec("/usr/bin/network-gcxy.sh force_auth &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "gcxy"))
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
    luci.sys.exec("/usr/bin/network-gcxy.sh test_now &")
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "gcxy"))
end

--页面自动刷新
local ajax_js = s:option(DummyValue, "_ajax_js")
ajax_js.rawhtml = true
ajax_js.value = [[
<script type="text/javascript">
    function updateStatus() {
        // 如果用户正在输入手机号，不执行更新
        var phoneInput = document.getElementsByName('cbid.network-gcxy.main.phone')[0];
        if (document.activeElement === phoneInput) return;

        XHR.get(']] .. luci.dispatcher.build_url("admin", "network", "gcxy") .. [[', null,
            function(x, data) {
                var tempDiv = document.createElement('div');
                tempDiv.innerHTML = x.responseText;

                // 1. 更新日志文本框 (并自动滚动到底部)
                var newLog = tempDiv.querySelector('textarea[name="cbid.network-gcxy.main.logview"]');
                var oldLog = document.querySelector('textarea[name="cbid.network-gcxy.main.logview"]');
                if (newLog && oldLog && oldLog.value !== newLog.value) {
                    oldLog.value = newLog.value;
                    oldLog.scrollTop = oldLog.scrollHeight;
                }

                // 2. 更新所有状态单元格 (包含图标的)
                var currentFields = document.querySelectorAll('.cbi-value-field');
                var newFields = tempDiv.querySelectorAll('.cbi-value-field');
                newFields.forEach(function(field, i) {
                    if (field.innerText.match(/[🟢⏳✅🔄🔴]/) && currentFields[i]) {
                        currentFields[i].innerHTML = field.innerHTML;
                    }
                });
            }
        );
    }
    // 2 秒刷新一次，响应极快
    setInterval(updateStatus, 2000);
</script>
]]

return m
