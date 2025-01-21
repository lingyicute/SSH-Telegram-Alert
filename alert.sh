#!/usr/bin/env bash
 
# Import credentials and library
. /opt/ssh-login-alert-telegram/credentials.config
. /opt/ssh-login-alert-telegram/alert-lib.sh

if [ -n "$SSH_CLIENT" ]; then
	SRV_HOSTNAME=$(hostname -f)
	CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
	LOCATION=$(get_ip_location "$CLIENT_IP")
	DATE="$(date "+%d %b %Y %H:%M")"

	# 准备消息文本
	TEXT="🔔 *SSH 登录成功*\\n"
	TEXT+="用户: *${USER}*\\n"
	TEXT+="服务器: *${SRV_HOSTNAME}*\\n"
	TEXT+="IP: \`${CLIENT_IP}\`\\n"
	TEXT+="位置: ${LOCATION}\\n"
	TEXT+="时间: ${DATE}"
	
	# 发送告警
	send_alert "$TEXT" || echo "发送告警失败"
fi
