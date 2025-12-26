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

#### 单用户发送

```bash
# 简单消息
./send.sh "这是一条测试消息"

# 自定义标题
./send.sh "标题" "内容"

# 从文件读取（适合长内容）
./send.sh -f message.txt
```

#### 多用户发送

⚠️ **注意**：go-wxpush 原生不支持多用户同时推送（虽然文档声称支持），需要使用 `send_all.sh` 脚本逐个发送。

```bash
# 批量发送到所有用户（从 run.sh 读取用户列表）
./send_all.sh -f message.txt

# 或指定内容
./send_all.sh "标题" "内容"
```

`send_all.sh` 会自动读取 `run.sh` 中配置的用户列表，逐个发送消息并显示每个用户的发送结果。

## 命令说明

### 服务管理

| 命令               | 说明     |
| ------------------ | -------- |
| `./run.sh start`   | 启动服务 |
| `./run.sh stop`    | 停止服务 |
| `./run.sh restart` | 重启服务 |
| `./run.sh logs`    | 查看日志 |
| `./run.sh status`  | 查看状态 |
| `./run.sh pull`    | 更新镜像 |

### 消息发送

| 命令                           | 说明               |
| ------------------------------ | ------------------ |
| `./send.sh "内容"`             | 发送简单消息       |
| `./send.sh "标题" "内容"`      | 发送带标题消息     |
| `./send.sh -f message.txt`     | 从文件读取内容发送 |
| `./send_all.sh -f message.txt` | 批量发送到所有用户 |

## 多用户说明

go-wxpush 虽然文档声称支持多用户，但实际上并未实现。本项目提供 `send_all.sh` 解决此问题：

- **原理**：读取 `run.sh` 中的用户列表，逐个向每个用户单独发送
- **优势**：可以看到每个用户的发送结果，失败时可以定位具体是哪个用户
- **使用**：在 `run.sh` 第 9 行配置多个用户，然后用 `send_all.sh` 发送即可

## 获取配置

[微信公众平台测试账号](https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login)

1. 扫码登录获取 `appid` 和 `appsecret`
2. 新增消息模板，获取 `template_id`（模板内容填 `内容: {{content.DATA}}`）
3. 关注测试公众号后，在用户列表获取 `openid`

## 消息模板

### 消息内容模板

项目提供多个精美的消息模板，存放在 `templates/` 目录：

| 模板文件               | 说明         | 使用场景               |
| ---------------------- | ------------ | ---------------------- |
| `holiday_greeting.txt` | 节日祝福     | 元旦、春节等节日问候   |
| `server_alert.txt`     | 服务器告警   | CPU、内存、磁盘告警    |
| `daily_reminder.txt`   | 每日提醒     | 待办事项、日程提醒     |
| `task_complete.txt`    | 任务完成通知 | 备份完成、脚本执行成功 |
| `security_alert.txt`   | 安全提醒     | 异常登录、安全警告     |

### 消息详情页模板

点击微信消息后跳转的页面，存放在 `html/` 目录：

| HTML 文件            | 风格     | 预览                   |
| -------------------- | -------- | ---------------------- |
| `detail.html`        | 紫色渐变 | 现代感，适合通知类消息 |
| `detail_dark.html`   | 暗黑主题 | 科技感，适合系统告警   |
| `detail_simple.html` | 简约卡片 | 清新风，适合日常提醒   |

### 使用方式

#### 1. 使用消息内容模板

```bash
# 使用模板发送
./send_all.sh -f templates/holiday_greeting.txt
```

#### 2. 自定义详情页（部署到 GitHub Pages）

1. **上传代码到 GitHub**
2. **启用 GitHub Pages**（Settings → Pages → Source 选择 main 分支）
3. **修改 `.env` 文件**，设置 `base_url`：

```bash
# .env 文件
BASE_URL="https://你的用户名.github.io/wx-push/html"
```

4. **重启服务**：

```bash
./run.sh restart
```

现在点击微信消息会跳转到你的自定义页面！

#### 3. 从 GitHub 直接使用内容模板

```bash
# 从 GitHub 拉取模板发送
curl -s https://raw.githubusercontent.com/你的用户名/wx-push/main/templates/holiday_greeting.txt | ./send_all.sh -f -
```
