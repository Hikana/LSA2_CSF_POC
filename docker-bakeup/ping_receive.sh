#!/bin/bash

MAIN_HOST="192.168.123.123"
DR_HOST="10.107.47.195"
SERVICE_PORT=8080
DNS_FLAG_FILE="/home/dnsserver/dns_request"
TUNNEL_PORT=$SERVICE_PORT

# 檢查是否已有現有 SSH Tunnel
check_existing_tunnel() {
    lsof -i TCP:$TUNNEL_PORT | grep ssh >/dev/null
}

# 清除現有的 SSH Tunnel
kill_existing_tunnel() {
    pkill -f "ssh -L $SERVICE_PORT"
}

# 取得封包遺失率
get_loss() {
    ping -c 10 $1 | grep -oP '\d+(?=% packet loss)' | head -n1
}

LOSS_MAIN=$(get_loss $MAIN_HOST)
LOSS_DR=999  # 預設值為高（代表尚未測試）

# 若 tunnel 存在則先清除
if check_existing_tunnel; then
    echo "移除現有的 SSH Tunnel..."
    kill_existing_tunnel
fi

if [ "$LOSS_MAIN" -lt 100 ]; then
    echo "主站可連線，建立 MAIN_HOST tunnel"
    ssh -L $SERVICE_PORT:$MAIN_HOST:$SERVICE_PORT -N -f mainsite@$MAIN_HOST
    [ -f "$DNS_FLAG_FILE" ] && rm -f "$DNS_FLAG_FILE"
else
    # 主站斷線：準備切換到 DR_SITE
    if [ ! -f "$DNS_FLAG_FILE" ]; then
        echo "主站無回應，檢查備援站..."
        LOSS_DR=$(get_loss $DR_HOST)
        if [ "$LOSS_DR" -lt 100 ]; then
            echo "備援站可用，建立 DR_HOST tunnel"
            ssh -L $SERVICE_PORT:$DR_HOST:$SERVICE_PORT -N -f jenne14294@$DR_HOST
            touch "$DNS_FLAG_FILE"
        else
            echo "主站與備援站皆無回應，不執行任何 tunnel"
        fi
    else
        echo "已經在備援狀態，主站仍不可用，不切換"
    fi
fi