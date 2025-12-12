#!/bin/bash

# ==========================================
# Poe x Claude Code 启动器 (v4.2 依赖修复版)
# ==========================================

set -e

# --- 基础配置 ---
DEFAULT_POE_BOT="gpt-5.2" 
LITELLM_PORT=4000
POE_API_ENDPOINT="https://api.poe.com/v1"
CONFIG_FILE=".poe_key"

# --- 颜色定义 ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚀 初始化 Poe x Claude Code 环境...${NC}"

# 1. 环境检查
if ! command -v python3 &> /dev/null; then echo -e "${RED}❌ 错误: 未找到 Python3${NC}"; exit 1; fi

# === 关键修复：检测是否安装了 proxy 所需的额外依赖 (例如 backoff) ===
if ! python3 -c "import backoff" &> /dev/null; then 
    echo -e "${YELLOW}📦 检测到缺失 Proxy 依赖，正在补全安装 'litellm[proxy]'...${NC}"
    # 注意：使用引号防止 zsh 报错
    pip install "litellm[proxy]" -q
else
    echo -e "${GREEN}✅ LiteLLM 及 Proxy 依赖已安装${NC}"
fi

# 2. 密钥处理
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

if [ -z "$POE_API_KEY" ]; then
    echo -e "${YELLOW}🔑 请输入你的 Poe API Key:${NC}"
    read -s USER_KEY
    if [ -z "$USER_KEY" ]; then
        echo -e "${RED}❌ 错误: API Key 不能为空！${NC}"
        exit 1
    fi
    export POE_API_KEY="$USER_KEY"
    echo "export POE_API_KEY='$USER_KEY'" > "$CONFIG_FILE"
    echo -e "${GREEN}✅ Key 已保存到 $CONFIG_FILE${NC}"
else
    MASKED_KEY="${POE_API_KEY:0:4}......${POE_API_KEY: -4}"
    echo -e "${GREEN}✅ 检测到现有 Key: $MASKED_KEY${NC}"
fi

# 3. 代理服务启动
if lsof -Pi :$LITELLM_PORT -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${GREEN}♻️  检测到后台代理已在运行 (端口 $LITELLM_PORT)，直接复用。${NC}"
    EXISTING_PROXY=true
else
    echo -e "${BLUE}🔌 准备启动代理服务...${NC}"
    
    echo -e "🤖 默认使用模型: ${GREEN}$DEFAULT_POE_BOT${NC}"
    echo -ne "   按回车确认，或输入其他 Bot 名称: "
    read INPUT_BOT
    BOT_NAME=${INPUT_BOT:-$DEFAULT_POE_BOT}
    echo -e "   使用模型: ${BLUE}$BOT_NAME${NC}"
    
    export OPENAI_API_KEY="$POE_API_KEY"
    
    # 清理旧日志
    rm -f litellm.log

    # 启动 LiteLLM
    nohup litellm --model "openai/$BOT_NAME" \
        --api_base "$POE_API_ENDPOINT" \
        --port $LITELLM_PORT \
        --alias "claude-3-5-sonnet-20241022" \
        --alias "claude-3-5-sonnet-latest" \
        --alias "claude-sonnet-4-5-20250929" \
        > litellm.log 2>&1 &
        
    LITELLM_PID=$!
    
    echo -ne "⏳ 正在连接 Poe..."
    sleep 3
    
    if ! kill -0 $LITELLM_PID 2>/dev/null; then
        echo -e "\n${RED}❌ 代理启动失败！请查看 litellm.log 获取详情。${NC}"
        echo -e "${YELLOW}日志最后 10 行:${NC}"
        tail -n 10 litellm.log
        exit 1
    fi
    echo -e "\n${GREEN}✅ 连接成功! (PID: $LITELLM_PID)${NC}"
    EXISTING_PROXY=false
fi

# 4. 启动 Claude Code
echo -e "${BLUE}🚀 正在启动 Claude Code...${NC}"
echo -e "${YELLOW}------------------------------------------------${NC}"

unset ANTHROPIC_AUTH_TOKEN
unset CLAUDE_API_KEY

export ANTHROPIC_BASE_URL="http://127.0.0.1:$LITELLM_PORT"
export ANTHROPIC_API_KEY="sk-fake-key-bypass" 

cleanup() {
    if [ "$EXISTING_PROXY" = false ]; then
        echo -e "\n${BLUE}🧹 正在关闭代理服务...${NC}"
        kill $LITELLM_PID 2>/dev/null
    fi
}
trap cleanup EXIT

# 启动
claude --model claude-sonnet-4-5-20250929