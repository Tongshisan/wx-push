#!/bin/bash
# ./send.sh -f message.txt

# 微信消息推送脚本
# 使用方法: 
#   ./send.sh "内容"                    # 使用默认标题
#   ./send.sh "标题" "内容"              # 自定义标题
#   ./send.sh -f message.txt           # 从文件读取（使用默认标题）
#   ./send.sh -f "标题" message.txt    # 从文件读取 + 自定义标题
#   ./send.sh                          # 交互模式，直接输入内容

#############################################
# 配置区域
#############################################
# 服务地址（本地部署）
HOST="http://127.0.0.1:5566"

# 默认标题（只传一个参数时使用）
DEFAULT_TITLE="小智的推送消息"

# 消息文件（可选，放在这里方便编辑长内容）
MESSAGE_FILE="$SCRIPT_DIR/message.txt"
#############################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 从 run.sh 读取 USERID
get_userid() {
    grep -E "^USERID=" "$SCRIPT_DIR/run.sh" | head -1 | cut -d'"' -f2
}

# 显示帮助
show_help() {
    echo "微信消息推送脚本"
    echo ""
    echo "用法:"
    echo "  ./send.sh \"消息内容\"                  # 使用默认标题"
    echo "  ./send.sh \"标题\" \"消息内容\"          # 自定义标题"
    echo "  ./send.sh -f message.txt              # 从文件读取内容"
    echo "  ./send.sh -f \"标题\" message.txt      # 从文件读取 + 自定义标题"
    echo "  ./send.sh                             # 交互模式"
    echo "  ./send.sh -h                          # 显示帮助"
    echo ""
    echo "示例:"
    echo "  ./send.sh \"服务器已重启\""
    echo "  ./send.sh \"告警\" \"CPU 使用率超过 90%\""
    echo "  echo \"长内容\" > msg.txt && ./send.sh -f msg.txt"
}

# 解析参数
if [ $# -eq 0 ]; then
    # 交互模式
    echo "📝 交互模式 - 输入消息内容（输入完成后按 Ctrl+D）:"
    echo "---"
    CONTENT=$(cat)
    echo "---"
    TITLE="$DEFAULT_TITLE"
    
    if [ -z "$CONTENT" ]; then
        echo "❌ 错误: 内容为空"
        exit 1
    fi
elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
elif [ "$1" = "-f" ]; then
    # 从文件读取模式
    if [ $# -eq 2 ]; then
        # ./send.sh -f file.txt
        TITLE="$DEFAULT_TITLE"
        FILE="$2"
    elif [ $# -eq 3 ]; then
        # ./send.sh -f "标题" file.txt
        TITLE="$2"
        FILE="$3"
    else
        echo "❌ 错误: -f 参数用法错误"
        echo "用法: ./send.sh -f [标题] 文件路径"
        exit 1
    fi
    
    if [ ! -f "$FILE" ]; then
        echo "❌ 错误: 文件不存在: $FILE"
        exit 1
    fi
    
    CONTENT=$(cat "$FILE")
elif [ $# -eq 1 ]; then
    TITLE="$DEFAULT_TITLE"
    CONTENT="$1"
else
    TITLE="$1"
    CONTENT="$2"
fi

# URL 编码函数
urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('''$1''', safe=''))"
}

# 编码参数
ENCODED_TITLE=$(urlencode "$TITLE")
ENCODED_CONTENT=$(urlencode "$CONTENT")

# 获取用户列表
USERID=$(get_userid)
USER_COUNT=$(echo "$USERID" | tr ',' '\n' | wc -l | tr -d ' ')

# 发送请求
echo "📤 发送消息..."
echo "   标题: $TITLE"
echo "   内容: $CONTENT"
echo "   用户: $USERID ($USER_COUNT 人)"
echo ""

RESPONSE=$(curl -s "${HOST}/wxsend?title=${ENCODED_TITLE}&content=${ENCODED_CONTENT}")

# 检查结果
if echo "$RESPONSE" | grep -q '"errcode":0'; then
    echo "✅ 发送成功!"
else
    echo "❌ 发送失败"
    echo "   响应: $RESPONSE"
    exit 1
fi

