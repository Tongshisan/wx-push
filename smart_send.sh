#!/bin/bash

# 智能推送脚本 - 使用 AI 识别意图并发送消息
# 使用方法: ./smart_send.sh "给我朋友发个元旦祝福"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GROUPS_FILE="$SCRIPT_DIR/groups.conf"
HOST="http://127.0.0.1:5566"

#############################################
# 配置区域
#############################################
# OpenAI API 配置（需要自己申请）
OPENAI_API_KEY="${OPENAI_API_KEY:-}"  # 从环境变量读取，或者直接填写
OPENAI_API_URL="https://api.openai.com/v1/chat/completions"
# 也可以使用其他兼容 OpenAI API 的服务，比如:
# OPENAI_API_URL="https://api.deepseek.com/v1/chat/completions"

DEFAULT_TITLE="小智的推送消息"
#############################################

# 显示帮助
show_help() {
    echo "智能推送脚本 - 使用 AI 识别意图"
    echo ""
    echo "用法:"
    echo "  ./smart_send.sh \"给朋友发个元旦祝福\""
    echo "  ./smart_send.sh \"通知家人晚上聚餐\""
    echo "  ./smart_send.sh \"给所有人发消息：会议延期到下午3点\""
    echo ""
    echo "分组管理:"
    echo "  编辑 groups.conf 文件配置用户分组"
    echo ""
    echo "AI 配置:"
    echo "  export OPENAI_API_KEY='your-api-key'"
    echo "  或直接在脚本中配置 OPENAI_API_KEY"
}

# 检查参数
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 检查 API Key
if [ -z "$OPENAI_API_KEY" ]; then
    echo "❌ 错误: 未配置 OPENAI_API_KEY"
    echo "请设置环境变量: export OPENAI_API_KEY='your-api-key'"
    echo "或在脚本中直接配置"
    exit 1
fi

# 读取分组配置
get_group_users() {
    local group=$1
    grep "^${group}=" "$GROUPS_FILE" 2>/dev/null | cut -d'=' -f2
}

# 调用 AI 解析意图
parse_intent() {
    local user_input="$1"
    
    # 读取所有可用分组
    local available_groups=$(grep -E "^[^#].*=" "$GROUPS_FILE" | cut -d'=' -f1 | tr '\n' ',' | sed 's/,$//')
    
    # 构造 prompt
    local prompt="你是一个消息推送助手。用户会说一句话，你需要解析出：
1. 目标分组（可选值：${available_groups}）
2. 消息标题（如果没有明确说明，使用合适的默认标题）
3. 消息内容

用户输入：\"${user_input}\"

请以 JSON 格式返回，格式如下：
{
  \"group\": \"目标分组名\",
  \"title\": \"消息标题\",
  \"content\": \"消息内容\"
}

注意：
- 如果用户说\"朋友\"，对应 friends 分组
- 如果用户说\"家人\"，对应 family 分组  
- 如果用户说\"游戏搭子\"或\"游戏\"，对应 gamers 分组
- 如果用户说\"所有人\"或\"大家\"，对应 all 分组
- 只返回 JSON，不要其他文字"

    # 调用 OpenAI API
    local response=$(curl -s "$OPENAI_API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-3.5-turbo\",
            \"messages\": [
                {\"role\": \"system\", \"content\": \"你是一个消息推送助手，只返回 JSON 格式的结果。\"},
                {\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}
            ],
            \"temperature\": 0.3
        }")
    
    # 提取 JSON 结果
    echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null
}

# URL 编码函数
urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('''$1''', safe=''))"
}

# 主逻辑
echo "🤖 AI 正在理解你的意图..."
echo ""

# 调用 AI 解析
AI_RESULT=$(parse_intent "$1")

if [ -z "$AI_RESULT" ] || [ "$AI_RESULT" = "null" ]; then
    echo "❌ AI 解析失败，请检查 API 配置"
    exit 1
fi

# 解析 JSON 结果
GROUP=$(echo "$AI_RESULT" | jq -r '.group' 2>/dev/null)
TITLE=$(echo "$AI_RESULT" | jq -r '.title' 2>/dev/null)
CONTENT=$(echo "$AI_RESULT" | jq -r '.content' 2>/dev/null)

echo "📊 AI 解析结果："
echo "   目标分组: $GROUP"
echo "   标题: $TITLE"
echo "   内容: $CONTENT"
echo ""

# 获取分组用户
USERS=$(get_group_users "$GROUP")

if [ -z "$USERS" ]; then
    echo "❌ 错误: 未找到分组 '$GROUP'"
    echo "可用分组："
    grep -E "^[^#].*=" "$GROUPS_FILE" | cut -d'=' -f1
    exit 1
fi

# 确认发送
read -p "是否确认发送？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 已取消"
    exit 0
fi

# 发送消息
USER_ARRAY=(${USERS//,/ })
echo ""
echo "📤 开始发送..."
echo ""

SUCCESS=0
FAILED=0

ENCODED_TITLE=$(urlencode "$TITLE")
ENCODED_CONTENT=$(urlencode "$CONTENT")

for USERID in "${USER_ARRAY[@]}"; do
    echo "📧 发送到: $USERID"
    
    RESPONSE=$(curl -s "${HOST}/wxsend?title=${ENCODED_TITLE}&content=${ENCODED_CONTENT}&userid=${USERID}")
    
    if echo "$RESPONSE" | grep -q '"errcode":0'; then
        echo "   ✅ 成功"
        ((SUCCESS++))
    else
        echo "   ❌ 失败"
        ((FAILED++))
    fi
done

echo ""
echo "========================================="
echo "发送完成: 成功 $SUCCESS 个，失败 $FAILED 个"

