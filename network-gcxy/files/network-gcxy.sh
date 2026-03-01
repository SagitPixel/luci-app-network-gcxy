#!/bin/sh
# 路径: /usr/bin/network-gcxy.sh

# 确保能找到系统命令
export PATH="/usr/sbin:/usr/bin:/sbin:/bin"
LOG_FILE="/var/log/network_gcxy.log"

# --- [ 1. 核心认证函数 (保留原脚本的 Curl 细节) ] ---

do_auth() {
    local phone="$1"
    # 自动获取 MAC 并转换为 xx-xx 格式
    . /lib/functions/network.sh
    network_get_physdev dev_name "wan"
    [ -z "$dev_name" ] && dev_name="eth0"
    raw_mac=$(cat /sys/class/net/$dev_name/address 2>/dev/null)
    macdizhi=$(echo "$raw_mac" | tr '[:lower:]' '[:upper:]' | sed 's/:/-/g')
    [ -z "$macdizhi" ] && macdizhi="00-00-00-00-00-00"

    # 获取 IP (使用 ubus + ip 双重保障)
    userip=$(ubus call network.interface.wan status | jsonfilter -e '@["ipv4-address"][0].address' 2>/dev/null)
    [ -z "$userip" ] && userip=$(ip -4 addr show "br-wan" 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | head -n 1)
    [ -z "$userip" ] && userip=$(ip -4 addr show "wan" 2>/dev/null | grep -oE 'inet ([0-9]{1,3}\.){3}[0-9]{1,3}' | awk '{print $2}' | head -n 1)

    if [ -n "$userip" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 获取 IP: $userip, MAC: $macdizhi，开始认证..." >> "$LOG_FILE"
        
        redirect_url="http://36.189.241.20:9956/?userip=$userip&wlanacname=&nasip=117.191.7.53&usermac=$macdizhi"
        encoded_url=$(echo "$redirect_url" | sed 's/&/%26/g; s/:/%3A/g; s/\//%2F/g')

        # 这里的 Curl 参数完全对应你之前的原始脚本
        auth_result=$(curl -s -k 'http://36.189.241.20:9956/web/connect' \
          -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
          -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36' \
          -H 'Referer: http://36.189.241.20:9956/web' \
          --data-raw "web-auth-user=g${phone}&web-auth-password=123123&remember-credentials=false&redirect-url=$encoded_url")
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 认证结果: $auth_result" >> "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：未获取到 WAN 口 IP" >> "$LOG_FILE"
    fi
}

# --- [ 2. 逻辑分支处理 ] ---

# 读取 LuCI 配置
ENABLED=$(uci -q get network-gcxy.main.enabled)
PHONE=$(uci -q get network-gcxy.main.phone)

case "$1" in
    "force")
        # 对应网页“手动认证”按钮
        [ -z "$PHONE" ] && echo "未设置手机号" >> "$LOG_FILE" && exit 1
        do_auth "$PHONE"
        ;;
    "test")
        # 对应网页“立即检测”按钮
        if curl -I -s -m 3 "https://www.baidu.com" >/dev/null; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 手动检测：网络通畅 ✅" >> "$LOG_FILE"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 手动检测：网络不通 ❌" >> "$LOG_FILE"
        fi
        ;;
    *)
        # --- 默认模式：这里就是你原脚本的 while true 循环逻辑 ---
        [ "$ENABLED" != "1" ] && exit 0
        
        # 这里的参数完全照搬你的原脚本
        TARGET_URLS="https://www.baidu.com https://www.qq.com https://www.douyin.com"
        MIN_INTERVAL=120
        MAX_INTERVAL=240
        TIMEOUT=3

        while true; do
            # 重新读取开关，防止网页关闭了脚本还在跑
            [ "$(uci -q get network-gcxy.main.enabled)" != "1" ] && exit 0
            
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始网络检测..." >> "$LOG_FILE"
            failed_count=0
            
            for url in $TARGET_URLS; do
                if ! curl -I -s -m "$TIMEOUT" "$url" >/dev/null 2>&1; then
                    failed_count=$((failed_count + 1))
                fi
            done

            if [ "$failed_count" -eq 3 ]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 全部失败，重启 WAN 接口..." >> "$LOG_FILE"
                /sbin/ifdown wan
                sleep 2
                /sbin/ifup wan
                sleep 10
                do_auth "$PHONE"
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 网络正常，无需操作。" >> "$LOG_FILE"
            fi

            # 保持日志文件不要太大
            sed -i ':a;$q;N;101,$D;ba' "$LOG_FILE"

            # 随机间隔
            RANDOM_INTERVAL=$((MIN_INTERVAL + RANDOM % (MAX_INTERVAL - MIN_INTERVAL + 1)))
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 等待 $RANDOM_INTERVAL 秒..." >> "$LOG_FILE"
            sleep "$RANDOM_INTERVAL"
        done
        ;;
esac