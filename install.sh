#!/usr/bin/env bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "请以 root 权限运行此脚本"
    exit 1
fi

# 检查必要的依赖
check_dependencies() {
    local missing_deps=()
    
    # 检查 curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # 检查 jq
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    # 如果有缺失的依赖，提示安装
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "缺少必要的依赖："
        printf '%s\n' "${missing_deps[@]}"
        echo "请使用包管理器安装这些依赖。"
        echo "例如，在 Debian/Ubuntu 系统上："
        echo "apt-get update && apt-get install -y ${missing_deps[*]}"
        exit 1
    fi
}

# 检查依赖
check_dependencies

# 安装fail2ban
install_fail2ban() {
    echo "正在安装fail2ban..."
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y fail2ban
    elif command -v yum >/dev/null 2>&1; then
        yum install -y fail2ban
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y fail2ban
    else
        echo "警告：无法检测到支持的包管理器，请手动安装fail2ban"
        return 1
    fi
    
    # 启动fail2ban服务
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable fail2ban
        systemctl start fail2ban
    else
        service fail2ban start
    fi
}

# 如果fail2ban未安装，则安装它
if ! command -v fail2ban-client >/dev/null 2>&1; then
    install_fail2ban
fi

# 设置安装目录
INSTALL_DIR="/opt/ssh-login-alert-telegram"

# 检查是否已安装
if [ -d "$INSTALL_DIR" ]; then
    echo "检测到已存在安装，是否重新安装？[y/N]"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "安装已取消"
        exit 0
    fi
fi

# 创建安装目录
mkdir -p "$INSTALL_DIR" || {
    echo "创建安装目录失败"
    exit 1
}

# 复制文件
echo "正在复制文件..."
cp alert.sh "$INSTALL_DIR/" || exit 1
cp alert-lib.sh "$INSTALL_DIR/" || exit 1
cp credentials.config "$INSTALL_DIR/" || exit 1
cp fail2ban-alert.sh "$INSTALL_DIR/" || exit 1

# 设置文件权限
echo "正在设置文件权限..."
chown root:root "$INSTALL_DIR/alert.sh"
chmod 755 "$INSTALL_DIR/alert.sh"
chown root:root "$INSTALL_DIR/alert-lib.sh"
chmod 755 "$INSTALL_DIR/alert-lib.sh"
chown root:root "$INSTALL_DIR/credentials.config"
chmod 600 "$INSTALL_DIR/credentials.config"
chown root:root "$INSTALL_DIR/fail2ban-alert.sh"
chmod 755 "$INSTALL_DIR/fail2ban-alert.sh"

# 配置 SSH 登录脚本
echo "正在配置 SSH 登录脚本..."
echo "#!/bin/bash" > /etc/profile.d/ssh-alert.sh
echo "$INSTALL_DIR/alert.sh" >> /etc/profile.d/ssh-alert.sh
chmod +x /etc/profile.d/ssh-alert.sh

# 配置 fail2ban
if [ -d "/etc/fail2ban" ]; then
    echo "正在配置 fail2ban..."
    # 创建 fail2ban 动作配置
    cat > /etc/fail2ban/action.d/telegram-notify.conf << EOL
[Definition]
actionstart =
actionstop =
actioncheck =
actionban = $INSTALL_DIR/fail2ban-alert.sh ban <ip> <name>
actionunban = $INSTALL_DIR/fail2ban-alert.sh unban <ip> <name>
EOL

    # 创建 jail.local 配置
    cat > /etc/fail2ban/jail.local << EOL
[DEFAULT]
# 封禁时间：20分钟
bantime = 1200
# 检测时间窗口：20分钟
findtime = 1200
# 最大尝试次数：4次
maxretry = 4

[sshd]
enabled = true
filter = sshd
port = ssh
logpath = %(sshd_log)s
# 使用默认的 sshd filter，它已经包含了所有需要的规则
action = %(action_)s
         telegram-notify[name=%(__name__)s]
EOL

    # 删除未使用的配置文件
    rm -f /etc/fail2ban/filter.d/sshd-notify.conf

    # 重启 fail2ban
    if systemctl is-active --quiet fail2ban; then
        systemctl restart fail2ban
    else
        echo "警告：fail2ban 服务未运行"
    fi
else
    echo "警告：未检测到 fail2ban，登录失败告警功能将不可用"
fi

echo "安装完成！"
echo "请编辑 $INSTALL_DIR/credentials.config 配置文件"
echo "如果要使用登录失败告警功能，请确保已安装 fail2ban" 