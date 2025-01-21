# SSH Login Alert Telegram Bot

这是一个用于在 SSH 登录时通过 Telegram 发送通知的系统。它由一个 Bash 脚本和一个 Cloudflare Worker 组成。

## 功能特点

- SSH 登录实时通知
- SSH 登录失败告警（通过 fail2ban 集成）
- 支持多个 Telegram 用户/频道
- 包含登录 IP 信息
- 使用 Cloudflare Worker 作为中继服务
- 支持 Markdown 格式消息

## 安装步骤

1. 克隆仓库：
```bash
git clone https://github.com/yourusername/ssh-login-alert-telegram.git
cd ssh-login-alert-telegram
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

# 添加你的 Telegram 用户 ID 或频道 ID
USERID=( "YOUR_TELEGRAM_ID" "YOUR_CHANNEL_ID" )

# 设置用于验证的令牌
AUTH_TOKEN="your-secure-token-here"
```

4. 部署 Cloudflare Worker：
   - 在 Cloudflare Workers 中创建新的 Worker
   - 复制 `worker.js` 的内容到 Worker 编辑器
   - 在 Worker 的环境变量中设置：
     - `AUTH_TOKEN`：与 credentials.config 中的值相同
     - `BOT_TOKEN`：你的 Telegram Bot Token

## 登录失败告警功能

此功能需要安装 fail2ban：

1. 安装 fail2ban（Ubuntu/Debian）：
```bash
sudo apt update
sudo apt install fail2ban
```

2. 安装脚本会自动配置 fail2ban 使用 Telegram 通知。如果需要手动配置：
   - 检查 `/etc/fail2ban/action.d/telegram-notify.conf` 是否存在
   - 确认 `/etc/fail2ban/jail.local` 中包含 `action = telegram-notify[name=%(__name__)s]`

3. 重启 fail2ban：
```bash
sudo systemctl restart fail2ban
```

## 安全建议

1. 确保 credentials.config 文件权限正确（600）
2. 使用强密码作为 AUTH_TOKEN
3. 定期更换 AUTH_TOKEN
4. 监控 Worker 的访问日志
5. 定期检查 fail2ban 日志

## 故障排除

如果通知没有发送：
1. 检查 credentials.config 中的配置是否正确
2. 确认 Telegram Bot Token 是否有效
3. 检查 Worker 是否正常运行
4. 查看系统日志中的错误信息
5. 检查 fail2ban 状态：`sudo systemctl status fail2ban`

## 许可证

GPLv3 License
