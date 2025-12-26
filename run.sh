#!/bin/bash

# go-wxpush Docker 启动脚本
# 使用方法: ./run.sh [start|stop|restart|logs|status]

#############################################
# ⬇️ 用户ID列表 - 在这里修改，多个用逗号分隔 ⬇️
#############################################
USERID="ofeXA2NVKFCQLc-npcXlokK6LF-Y,ofeXA2EzqsWHGLDwhfq2QNTxzufw,ofeXA2Gv-ybqCG-2xifu9PIYi8ys"
# USERID="ofeXA2NVKFCQLc-npcXlokK6LF-Y"
# USERID="ofeXA2Gv-ybqCG-2xifu9PIYi8ys"
# USERID="ofeXA2EzqsWHGLDwhfq2QNTxzufw"
#############################################

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# 检查 .env 文件是否存在
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ 错误: 找不到 .env 文件"
    echo "请确保 .env 文件存在于: $ENV_FILE"
    exit 1
fi

# 加载环境变量
set -a
source "$ENV_FILE"
set +a

# 显示配置信息
show_config() {
    echo "📋 当前配置:"
    echo "   端口: $PORT"
    echo "   标题: $TITLE"
    echo "   APPID: ${APPID:0:8}..."
    echo "   用户数: $(echo "$USERID" | tr ',' '\n' | wc -l | tr -d ' ')"
    echo "   用户列表: $USERID"
    echo "   容器名: $CONTAINER_NAME"
    echo "   镜像: $IMAGE"
    echo ""
}

# 启动容器
start() {
    echo "🚀 启动 go-wxpush 服务..."
    show_config
    
    # 先确保旧容器完全停止
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "⚠️  容器 $CONTAINER_NAME 已存在，正在删除..."
        docker stop "$CONTAINER_NAME" 2>/dev/null
        docker rm "$CONTAINER_NAME" 2>/dev/null
        sleep 1  # 等待资源释放
    fi
    
    # 启动新容器
    docker run -it -d -p "$PORT:$PORT" --init --name "$CONTAINER_NAME" "$IMAGE" \
        -port "$PORT" \
        -title "$TITLE" \
        -content "$CONTENT" \
        -appid "$APPID" \
        -secret "$SECRET" \
        -userid "$USERID" \
        -template_id "$TEMPLATE_ID" \
        -base_url "https://tongshisan.github.io/wx-push/html" \
        -tz "$TZ"
    
    if [ $? -eq 0 ]; then
        echo "✅ 服务启动成功!"
        echo "   访问地址: http://127.0.0.1:$PORT/wxsend"
        echo "   消息详情: http://127.0.0.1:$PORT/detail"
    else
        echo "❌ 服务启动失败"
        exit 1
    fi
}

# 停止容器
stop() {
    echo "🛑 停止 go-wxpush 服务..."
    docker stop "$CONTAINER_NAME" 2>/dev/null
    docker rm "$CONTAINER_NAME" 2>/dev/null
    echo "✅ 服务已停止"
}

# 重启容器
restart() {
    echo "🔄 重启 go-wxpush 服务..."
    stop
    start
}

# 查看日志
logs() {
    echo "📜 查看日志 (Ctrl+C 退出)..."
    docker logs -f "$CONTAINER_NAME"
}

# 查看状态
status() {
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo "✅ 服务运行中"
        docker ps --filter "name=$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "❌ 服务未运行"
    fi
}

# 更新镜像
pull() {
    echo "📥 拉取最新镜像..."
    docker pull "$IMAGE"
    echo "✅ 镜像更新完成"
}

# 主逻辑
case "${1:-start}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs
        ;;
    status)
        status
        ;;
    pull)
        pull
        ;;
    config)
        show_config
        ;;
    *)
        echo "用法: $0 {start|stop|restart|logs|status|pull|config}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动服务 (默认)"
        echo "  stop    - 停止服务"
        echo "  restart - 重启服务"
        echo "  logs    - 查看日志"
        echo "  status  - 查看状态"
        echo "  pull    - 更新镜像"
        echo "  config  - 显示配置"
        exit 1
        ;;
esac

