#!/bin/sh
# 路径: /usr/bin/network-gcxy.sh

LOG_FILE="/var/log/network_gcxy.log"

# --- [ 1. 函数定义 ] ---

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
}

# 认证执行函数 (封装核心认证逻辑)
do_auth() {
    # 重新获取最新的 MAC (防止硬件变更)
    . /lib/functions/network.sh
    network_get_physdev dev_name "wan"
    raw_mac=$(cat /sys/class/net/$dev_name/address 2>/dev/null)
    macdizhi=$(echo "$raw_mac" | sed 's/:/-/g')
    [ -z "$macdizhi" ] && macdizhi="00-00-00-00-00-00"

    # 获取 IP
    userip=$(ip -4 addr show "br-wan" 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | head -n 1)
    [ -z "$userip" ] && userip=$(ip -4 addr show "wan" 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | head -n 1)

    if [ -n "$userip" ]; then
        log "开始认证流程 (IP: $userip, MAC: $macdizhi)"
        redirect_url="http://36.189.241.20:9956/?userip=$userip&wlanacname=&nasip=117.191.7.53&usermac=$macdizhi"
        encoded_url=$(echo "$redirect_url" | sed 's/&/%26/g; s/:/%3A/g; s/\//%2F/g')
        
        auth_result=$(curl -s 'http://36.189.241.20:9956/web/connect' \
          -H 'Content-Type: application/x-www-form-urlencoded' \
          --data-raw "web-auth-user=g${1}&web-auth-password=123123&remember-credentials=false&redirect-url=$encoded_url")
        log "认证响应: $auth_result"
    else
        log "错误：无法获取到 WAN 口 IP，请确认接口已启动"
    fi
}

# --- [ 2. 读取配置 ] ---

ENABLED=$(uci -q get network-gcxy.main.enabled)
PHONE=$(uci -q get network-gcxy.main.phone)

# 自动清理过大日志
[ $(wc -l < "$LOG_FILE" 2>/dev/null || echo 0) -gt 500 ] && > "$LOG_FILE"

# --- [ 3. 逻辑分支处理 ] ---

case "$1" in
    "force")
        # 对应 LuCI 的“强制认证”按钮
        [ -z "$PHONE" ] && log "错误：未设置手机号" && exit 1
        do_auth "$PHONE"
        ;;
    "test")
        # 对应 LuCI 的“立即检测”按钮
        log "手动触发网络检测..."
        if curl -I -s -m 3 "https://www.baidu.com" > /dev/null 2>&1; then
            log "检测结果：✅ 网络当前是通畅的"
        else
            log "检测结果：❌ 无法访问外网"
        fi
        ;;
    *)
        # 默认模式 (procd 自动调用，无参数运行)
        [ "$ENABLED" != "1" ] || [ -z "$PHONE" ] && exit 0

        # 执行原有的循环检测逻辑
        failed=0
        for url in https://www.baidu.com https://www.qq.com https://www.douyin.com; do
            if ! curl -I -s -m 3 "$url" > /dev/null 2>&1; then
                failed=$((failed + 1))
            fi
        done

        if [ "$failed" -eq 3 ]; then
            log "网络故障 (3/3)，尝试修复..."
            /sbin/ifdown wan
            sleep 2
            /sbin/ifup wan
            sleep 10
            do_auth "$PHONE"
        fi
        ;;
esac