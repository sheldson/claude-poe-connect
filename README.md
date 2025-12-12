# Poe x Claude Code Launcher 🚀

这是一个简单的 Shell 脚本启动器，让你可以在 **Claude Code (CLI)** 中直接调用 **Poe** 的模型（如 GPT-5.2, Claude-3-Opus 等）。

它通过在本地后台运行一个轻量级的 `litellm` 代理，劫持 Claude Code 的 API 请求并转发给 Poe，从而实现：
- ✅ 使用 Poe 的订阅额度运行 Claude Code
- ✅ 使用 GPT-5.2 / Gemini 1.5 Pro 等非 Claude 模型来驱动 Claude CLI
- ✅ 自动处理依赖安装和 API Key 配置

## 前置要求

- macOS 或 Linux
- Python 3 Installed
- Node.js & Claude Code (`npm install -g @anthropic-ai/claude-code`)
- 一个有效的 [Poe](https://poe.com) 账号及 API Key

## 快速开始

1. **克隆仓库**
   ```bash
   git clone [https://github.com/你的用户名/claude-poe-connect.git](https://github.com/你的用户名/claude-poe-connect.git)
   cd claude-poe-connect
2. **运行启动器**

    ```bash

    chmod +x poe-launcher.sh
    ./poe-launcher.sh
3. **首次配置**

脚本会自动检测并安装 python 依赖 (litellm[proxy])。

首次运行会提示输入你的 Poe API Key (只需输入一次，会自动保存到本地 .poe_key)。

## 配置说明
你可以通过修改脚本顶部的变量来自定义默认模型：

    ```bash
    # 在 poe-launcher.sh 文件顶部
    DEFAULT_POE_BOT="gpt-5.2"  # 你想用的 Poe Bot Handle


## 原理
脚本利用 litellm 将 Poe 的 OpenAI 兼容接口转换为 Claude Code 能够识别的本地代理服务，并通过 Alias 劫持 claude-sonnet-4-5 等模型 ID。

## License
MIT
