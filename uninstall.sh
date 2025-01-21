#!/usr/bin/env bash

# 启用错误处理
set -e
set -o pipefail

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请以 root 权限运行此脚本"
    exit 1
fi

# 设置安装目录
INSTALL_DIR="/opt/ssh-login-alert-telegram"

# 确认卸载
echo "此操作将完全删除 SSH 登录告警系统。是否继续？[y/N]"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "卸载已取消"
    exit 0
fi

# 删除 fail2ban 配置
if [ -f "/etc/fail2ban/action.d/telegram-notify.conf" ]; then
    echo "正在移除 fail2ban 配置..."
    rm -f "/etc/fail2ban/action.d/telegram-notify.conf"
    
    # 从 jail.local 中移除配置
    if [ -f "/etc/fail2ban/jail.local" ]; then
        sed -i '/action = telegram-notify\[name=%(__name__)s\]/d' /etc/fail2ban/jail.local
        
        # 重启 fail2ban
        if systemctl is-active --quiet fail2ban; then
            systemctl restart fail2ban
        fi
    fi
fi

# 删除 SSH 登录脚本
echo "正在移除 SSH 登录脚本..."
rm -f /etc/profile.d/ssh-alert.sh

# 删除安装目录
if [ -d "$INSTALL_DIR" ]; then
    echo "正在删除安装目录..."
    rm -rf "$INSTALL_DIR"
fi

echo "卸载完成！"
echo "系统将在下次 SSH 登录时停止发送告警。" 