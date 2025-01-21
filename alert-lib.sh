#!/usr/bin/env bash

# 启用错误处理
set -e
set -o pipefail

# IP缓存文件（每天自动清理）
IP_CACHE_FILE="/tmp/ip_location_cache_$(date +%Y%m%d)"
touch "$IP_CACHE_FILE"
chmod 600 "$IP_CACHE_FILE"

# 从缓存获取IP位置信息
get_cached_location() {
    local ip=$1
    if [ -f "$IP_CACHE_FILE" ]; then
        local location
        location=$(grep "^${ip}=" "$IP_CACHE_FILE" | cut -d= -f2)
        if [ -n "$location" ]; then
            echo "$location"
            return 0
        fi
    fi
    return 1
}

# 缓存IP位置信息
cache_location() {
    local ip=$1
    local location=$2
    echo "${ip}=${location}" >> "$IP_CACHE_FILE"
}

# 使用ipapi.co查询位置
get_location_from_ipapi() {
    local ip=$1
    local location
    location=$(curl -s -m 5 "https://ipapi.co/${ip}/json/")
    if [ $? -eq 0 ] && [ -n "$location" ] && ! echo "$location" | grep -q "error"; then
        if command -v jq >/dev/null 2>&1; then
            local city region country
            city=$(echo "$location" | jq -r '.city // empty')
            region=$(echo "$location" | jq -r '.region // empty')
            country=$(echo "$location" | jq -r '.country_name // empty')
            if [ -n "$city" ] && [ -n "$country" ]; then
                echo "${city}, ${region}, ${country}"
                return 0
            fi
        fi
    fi
    return 1
}

# 使用ip-api.com查询位置（备用）
get_location_from_ipapi_com() {
    local ip=$1
    local location
    location=$(curl -s -m 5 "https://ip-api.com/json/${ip}")
    if [ $? -eq 0 ] && [ -n "$location" ] && echo "$location" | grep -q "\"status\":\"success\""; then
        if command -v jq >/dev/null 2>&1; then
            local city region country
            city=$(echo "$location" | jq -r '.city // empty')
            region=$(echo "$location" | jq -r '.regionName // empty')
            country=$(echo "$location" | jq -r '.country // empty')
            if [ -n "$city" ] && [ -n "$country" ]; then
                echo "${city}, ${region}, ${country}"
                return 0
            fi
        fi
    fi
    return 1
}

# 获取IP地理位置信息
get_ip_location() {
    local ip=$1
    local location
    
    # 尝试从缓存获取
    location=$(get_cached_location "$ip")
    if [ $? -eq 0 ]; then
        echo "$location"
        return 0
    fi
    
    # 尝试主要提供商
    location=$(get_location_from_ipapi "$ip")
    if [ $? -eq 0 ]; then
        cache_location "$ip" "$location"
        echo "$location"
        return 0
    fi
    
    # 尝试备用提供商
    location=$(get_location_from_ipapi_com "$ip")
    if [ $? -eq 0 ]; then
        cache_location "$ip" "$location"
        echo "$location"
        return 0
    fi
    
    echo "未知位置"
    return 1
}

# 发送告警消息到worker
send_alert() {
    local text=$1
    local max_retries=3
    local retry_count=0
    local success=false
    
    # 检查必要的配置
    if [ -z "$WORKER_URL" ] || [ -z "$AUTH_TOKEN" ]; then
        echo "错误：WORKER_URL 或 AUTH_TOKEN 未设置"
        return 1
    }
    
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
            "$WORKER_URL")
        
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