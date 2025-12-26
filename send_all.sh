#!/bin/bash

# 批量推送脚本 - 向多个用户分别发送
# 使用方法: ./send_all.sh "标题" "内容"
# 或者:    ./send_all.sh -f message.txt

#############################################
# 用户列表 - 从 run.sh 读取或手动定义
#############################################
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 从 run.sh 读取用户列表
get_users() {
    grep -E "^USERID=" "$SCRIPT_DIR/run.sh" | head -1 | cut -d'"' -f2
}

# 服务地址
HOST="http://127.0.0.1:5566"
DEFAULT_TITLE="小智的推送消息"
#############################################

# 解析参数（与 send.sh 相同）
if [ "$1" = "-f" ]; then
    if [ $# -eq 2 ]; then
        TITLE="$DEFAULT_TITLE"
        FILE="$2"
    elif [ $# -eq 3 ]; then
        TITLE="$2"
        FILE="$3"
    fi
    
    if [ ! -f "$FILE" ]; then
        echo "❌ 错误: 文件不存在: $FILE"
        exit 1
    fi
    
    CONTENT=$(cat "$FILE")
elif [ $# -eq 1 ]; then
    TITLE="$DEFAULT_TITLE"
    CONTENT="$1"
elif [ $# -eq 2 ]; then
    TITLE="$1"
    CONTENT="$2"
else
    echo "用法: $0 [-f] [标题] 内容|文件"
    exit 1
fi

# URL 编码函数
urlencode() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('''$1''', safe=''))"
}

# 编码参数
ENCODED_TITLE=$(urlencode "$TITLE")
ENCODED_CONTENT=$(urlencode "$CONTENT")

# 获取用户列表
USERS=$(get_users)
USER_ARRAY=(${USERS//,/ })

echo "📤 批量发送消息..."
echo "   标题: $TITLE"
echo "   内容: $CONTENT"
echo "   用户数: ${#USER_ARRAY[@]}"
echo ""

SUCCESS=0
FAILED=0

# 逐个发送
for USERID in "${USER_ARRAY[@]}"; do
    echo "📧 发送到: $USERID"
    
    RESPONSE=$(curl -s "${HOST}/wxsend?title=${ENCODED_TITLE}&content=${ENCODED_CONTENT}&userid=${USERID}")
    
    if echo "$RESPONSE" | grep -q '"errcode":0'; then
        echo "   ✅ 成功"
        ((SUCCESS++))
    else
        echo "   ❌ 失败: $RESPONSE"
        ((FAILED++))
    fi
done

echo ""
echo "========================================="
echo "发送完成: 成功 $SUCCESS 个，失败 $FAILED 个"

