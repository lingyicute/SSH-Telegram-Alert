# SSH Login Alert Telegram Bot

## Hi～

这是一个用于在 SSH 登录时通过 Telegram 发送告警的系统。它由一个 Bash 脚本和一个 Cloudflare Worker 组成。

## 功能特点

- SSH 登录实时通知
- SSH 登录失败告警（通过 fail2ban 集成）
  - 20分钟内4次失败尝试将导致IP被封禁20分钟
  - IP封禁和解封时都会发送告警
- 支持多个 Telegram 用户/频道
- 包含登录 IP 信息和地理位置
- 使用 Cloudflare Worker 作为中继服务
- 支持 Markdown 格式消息

## 安装步骤

1. 克隆仓库：
```bash
git clone https://github.com/lingyicute/SSH-Telegram-Alert.git
cd SSH-Telegram-Alert
```

2. 运行安装脚本：
```bash
sudo chmod +x install.sh
sudo ./install.sh
```

3. 配置 credentials.config：
```bash
# 编辑配置文件
sudo nano /opt/ssh-login-alert-telegram/credentials.config

# 添加 Telegram 接收者ID（支持多个，用逗号分隔）
CHAT_IDS="123456789,987654321"

# 设置用于验证的令牌（请使用随机生成的强密码）
AUTH_TOKEN="your-secure-token-here"
```

4. 部署 Cloudflare Worker：
   - 在 Cloudflare Workers 中创建新的 Worker
   - 复制 `worker.js` 的内容到 Worker 编辑器
   - 在 Worker 的环境变量中设置：
     - `AUTH_TOKEN`：与 credentials.config 中的值相同
     - `BOT_TOKEN`：你的 Telegram Bot Token
     - `CHAT_IDS`：与 credentials.config 中的值相同

## 登录失败告警功能

此功能需要安装 fail2ban，安装脚本会自动完成以下配置：

1. fail2ban 配置说明：
   - 监控 SSH 登录失败
   - 20分钟内失败4次将被封禁
   - 封禁时长为20分钟
   - 自动发送封禁和解封告警

2. 如果需要修改 fail2ban 配置：
```bash
# 编辑配置文件
sudo nano /etc/fail2ban/jail.local

# 重启服务
sudo systemctl restart fail2ban
```

3. 检查 fail2ban 状态：
```bash
# 查看服务状态
sudo systemctl status fail2ban

# 查看当前封禁列表
sudo fail2ban-client status sshd
```

## 安全建议

1. 确保 credentials.config 文件权限正确（600）
2. 使用随机生成的强密码作为 AUTH_TOKEN
3. 定期更换 AUTH_TOKEN
4. 监控 Worker 的访问日志
5. 定期检查 fail2ban 日志

## 故障排除

如果通知没有发送：
1. 检查 credentials.config 中的配置是否正确
2. 确认 Telegram Bot Token 是否有效
3. 检查 Worker 是否正常运行
4. 查看系统日志中的错误信息：
```bash
# 查看系统日志
sudo journalctl -u fail2ban
sudo tail -f /var/log/auth.log
```

## 许可证

SSH-Telegram-Alert is released under the GNU General Public License v3.0 (GPLv3).

Copyright (C) 2024 lingyicute.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see https://www.gnu.org/licenses.
