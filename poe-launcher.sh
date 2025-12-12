#!/bin/bash

# ==========================================
# Poe x Claude Code 启动器 (v5.1 兼容性修复版)
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

# 1. 环境检查 & 自动补全依赖
if ! command -v python3 &> /dev/null; then echo -e "${RED}❌ 错误: 未找到 Python3${NC}"; exit 1; fi

# 检测是否安装了 proxy 所需的额外依赖
if ! python3 -c "import backoff" &> /dev/null; then 
    echo -e "${YELLOW}📦 正在补全 LiteLLM Proxy 依赖...${NC}"
    pip install "litellm[proxy]" -q
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
    BOT_NAME=$DEFAULT_POE_BOT
    
    export OPENAI_API_KEY="$POE_API_KEY"
    
    rm -f litellm.log

    # === 关键修改 ===
    # 增加了 --drop_params 参数
    # 这会自动过滤掉 Poe 不支持的参数 (如 thinking)，防止 400 报错
    nohup litellm --model "openai/$BOT_NAME" \
        --api_base "$POE_API_ENDPOINT" \
        --port $LITELLM_PORT \
        --alias "claude-3-5-sonnet-20241022" \
        --alias "claude-3-5-sonnet-latest" \
        --alias "claude-sonnet-4-5-20250929" \
        --drop_params \
        > litellm.log 2>&1 &
        
    LITELLM_PID=$!
    
    sleep 2
    if ! kill -0 $LITELLM_PID 2>/dev/null; then
        echo -e "\n${RED}❌ 代理启动失败！日志如下：${NC}"
        tail -n 10 litellm.log
        exit 1
    fi
    echo -e "${GREEN}✅ 代理就绪 (PID: $LITELLM_PID)${NC}"
    EXISTING_PROXY=false
fi

# 4. 启动 Claude Code
echo -e "${BLUE}🚀 启动 Claude Code (已锁定 $DEFAULT_POE_BOT)...${NC}"
echo -e "${YELLOW}------------------------------------------------${NC}"

unset ANTHROPIC_AUTH_TOKEN
unset CLAUDE_API_KEY

export ANTHROPIC_BASE_URL="http://127.0.0.1:$LITELLM_PORT"
export ANTHROPIC_API_KEY="sk-fake-key-bypass" 

cleanup() {
    if [ "$EXISTING_PROXY" = false ]; then
        echo -e "\n${BLUE}🧹 关闭代理服务...${NC}"
        kill $LITELLM_PID 2>/dev/null
    fi
}
trap cleanup EXIT

# 启动
claude --model claude-sonnet-4-5-20250929