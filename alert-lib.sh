#!/usr/bin/env bash

# 获取IP地理位置信息
get_ip_location() {
    local ip=$1
    local location
    
    # 尝试使用ipapi.co获取位置信息，设置5秒超时
    location=$(curl -s -m 5 "https://ipapi.co/${ip}/json/")
    
    if [ $? -eq 0 ] && [ -n "$location" ]; then
        # 使用jq解析JSON响应
        if command -v jq >/dev/null 2>&1; then
            city=$(echo "$location" | jq -r '.city // empty')
            region=$(echo "$location" | jq -r '.region // empty')
            country=$(echo "$location" | jq -r '.country_name // empty')
            
            if [ -n "$city" ] && [ -n "$country" ]; then
                echo "${city}, ${region}, ${country}"
            else
                echo "未知位置"
            fi
        else
            echo "未知位置 (jq 工具未安装)"
        fi
    else
        echo "未知位置"
    fi
}

# 发送告警消息到worker
send_alert() {
    local text=$1
    local worker_url="https://sshnotify.92li.us.kg/notify"
    local max_retries=3
    local retry_count=0
    local success=false
    
    # 转义JSON特殊字符
    text=$(echo "$text" | sed 's/"/\\"/g')
    
    # 构建JSON数据
    local json_data="{\"text\":\"${text}\"}"
    
    while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
        # 发送请求
        response=$(curl -s -w "\n%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer ${AUTH_TOKEN}" \
            -d "$json_data" \
            "$worker_url")
        
        # 获取状态码和响应体
        http_code=$(echo "$response" | tail -n1)
        response_body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            success=true
            break
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $max_retries ]; then
                sleep $((retry_count * 2))
            fi
        fi
    done
    
    if [ "$success" = false ]; then
        echo "发送告警失败，已重试${retry_count}次。最后的响应：${response_body}"
        return 1
    fi
    
    return 0
} 