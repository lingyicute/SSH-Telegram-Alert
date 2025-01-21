#!/usr/bin/env bash

# 导入配置和库函数
. /opt/ssh-login-alert-telegram/credentials.config
. /opt/ssh-login-alert-telegram/alert-lib.sh

# 获取参数
ACTION=$1
IP=$2
SERVICE=$3

# 获取服务器信息
SRV_HOSTNAME=$(hostname -f)
DATE="$(date "+%d %b %Y %H:%M")"
LOCATION=$(get_ip_location "$IP")

# 构建消息
case "$ACTION" in
    "ban")
        TEXT="⛔️ *SSH 登录失败告警*\\n"
        TEXT+="服务: ${SERVICE}\\n"
        TEXT+="服务器: *${SRV_HOSTNAME}*\\n"
        TEXT+="IP: \`${IP}\`\\n"
        TEXT+="位置: ${LOCATION}\\n"
        TEXT+="时间: ${DATE}"
        ;;
    "unban")
        TEXT="✅ *SSH 封禁解除*\\n"
        TEXT+="服务: ${SERVICE}\\n"
        TEXT+="服务器: *${SRV_HOSTNAME}*\\n"
        TEXT+="IP: \`${IP}\`\\n"
        TEXT+="位置: ${LOCATION}\\n"
        TEXT+="时间: ${DATE}"
        ;;
    *)
        echo "未知动作: $ACTION"
        exit 1
        ;;
esac

# 发送告警
send_alert "$TEXT" || echo "发送告警失败" 