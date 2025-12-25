# wx-push

微信消息推送服务，基于 [go-wxpush](https://github.com/hezhizheng/go-wxpush)

[测试号地址](https://mp.weixin.qq.com/debug/cgi-bin/sandboxinfo?action=showinfo&t=sandbox/
index)

## 快速开始

### 1. 配置

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置文件，填入实际值
vim .env
```

### 2. 配置用户 ID

编辑 `run.sh` 第 9 行，填入接收消息的用户 openid：

```bash
USERID="用户1的openid,用户2的openid"
```

### 3. 启动服务

```bash
./run.sh start
```

### 4. 发送消息

```bash
# 简单消息
./send.sh "这是一条测试消息"

# 自定义标题
./send.sh "标题" "内容"

# 从文件读取（适合长内容）
./send.sh -f message.txt
```

## 命令说明

| 命令               | 说明     |
| ------------------ | -------- |
| `./run.sh start`   | 启动服务 |
| `./run.sh stop`    | 停止服务 |
| `./run.sh restart` | 重启服务 |
| `./run.sh logs`    | 查看日志 |
| `./run.sh status`  | 查看状态 |
| `./run.sh pull`    | 更新镜像 |

## 获取配置

[微信公众平台测试账号](https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login)

1. 扫码登录获取 `appid` 和 `appsecret`
2. 新增消息模板，获取 `template_id`（模板内容填 `内容: {{content.DATA}}`）
3. 关注测试公众号后，在用户列表获取 `openid`
