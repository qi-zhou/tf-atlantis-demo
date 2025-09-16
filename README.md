# Simple Terraform Atlantis Demo

🚀 **简化的 Terraform + Atlantis 自动化工作流程演示**

这是一个最简化的 Atlantis 演示项目，使用 null_resource 来展示基本的 Terraform + Atlantis 工作流程。

## 🎯 项目目标

- 演示 Atlantis 的基本工作流程
- 使用最简单的 Terraform 配置（null_resource）
- 本地运行 Atlantis 服务器
- 使用 ngrok 暴露本地服务到 GitHub webhook

## 📁 项目结构

```
.
├── terraform/
│   ├── main.tf          # 简单的 null_resource
│   ├── variables.tf     # 基本变量
│   └── outputs.tf       # 输出定义
├── atlantis.yaml        # Atlantis 配置
├── docker-compose.yml   # Docker 配置
├── demo-atlantis.sh     # 一键演示脚本 🆕
├── start-atlantis.sh    # 启动 Atlantis 服务器 🆕
├── stop-atlantis.sh     # 停止 Atlantis 服务器 🆕
├── .env.example         # 环境变量模板
├── .gitignore          # Git 忽略文件
└── README.md           # 本文件
```

## 🚀 快速开始

### 方法一：使用演示脚本（推荐）

```bash
# 运行一键演示脚本
./demo-atlantis.sh
```

这个脚本会自动：
- ✅ 检查并安装必要的依赖（Terraform, ngrok）
- ✅ 初始化和验证 Terraform 配置
- ✅ 启动 ngrok 隧道
- ✅ 显示完整的配置信息和下一步操作

### 方法二：使用 Atlantis 服务器脚本

```bash
# 启动 Atlantis 服务器
./start-atlantis.sh

# 在另一个终端启动 ngrok
ngrok http 4141

# 停止 Atlantis 服务器
./stop-atlantis.sh
```

### 方法三：手动设置

#### 前置要求

- [Docker](https://docs.docker.com/get-docker/) 和 Docker Compose
- [ngrok](https://ngrok.com/) (已安装)
- GitHub 账号和个人访问令牌

### 1. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件
vim .env
```

需要配置的变量：
- `ATLANTIS_GH_USER` - 你的 GitHub 用户名
- `ATLANTIS_GH_TOKEN` - GitHub 个人访问令牌 (需要 repo 权限)
- `ATLANTIS_GH_WEBHOOK_SECRET` - 自定义的 webhook 密钥
- `ATLANTIS_REPO_ALLOWLIST` - 当前仓库路径 (github.com/qi.zhou/tf-atlantis-demo)

### 2. 启动 ngrok

```bash
# 启动 ngrok 暴露本地 4141 端口
ngrok http 4141
```

记录 ngrok 提供的 HTTPS URL (例如: https://abc123.ngrok.io)

### 3. 更新环境变量

将 ngrok URL 添加到 .env 文件：
```bash
ATLANTIS_ATLANTIS_URL=https://your-ngrok-url.ngrok.io
```

### 4. 启动 Atlantis

```bash
# 启动 Atlantis 服务器
docker-compose up -d

# 查看日志
docker-compose logs -f atlantis-demo
```

### 5. 配置 GitHub Webhook

1. 进入 GitHub 仓库设置 → Webhooks → Add webhook
2. 配置：
   - **Payload URL**: `https://your-ngrok-url.ngrok.io/events`
   - **Content type**: `application/json`
   - **Secret**: 你在 .env 中设置的 `ATLANTIS_GH_WEBHOOK_SECRET`
   - **Events**: 选择 "Pull requests" 和 "Issue comments"

### 6. 测试工作流程

```bash
# 创建测试分支
git checkout -b test-atlantis

# 修改 Terraform 配置 (添加一个注释)
echo '# Test change' >> terraform/main.tf

# 提交并推送
git add .
git commit -m "test: add comment to trigger atlantis"
git push origin test-atlantis

# 创建 Pull Request
gh pr create --title "Test Atlantis" --body "Testing Atlantis workflow"
```

### 7. 使用 Atlantis 命令

在 PR 评论中使用：
- `atlantis plan` - 生成 Terraform 计划
- `atlantis apply` - 应用 Terraform 更改
- `atlantis help` - 显示帮助信息

## 🔧 故障排除

### 常见问题

1. **Atlantis 无法启动**
   ```bash
   # 检查日志
   docker-compose logs atlantis-demo

   # 检查环境变量
   cat .env
   ```

2. **GitHub webhook 不工作**
   - 确认 ngrok 正在运行
   - 检查 webhook URL 是否正确
   - 验证 webhook secret 是否匹配

3. **Terraform 计划失败**
   ```bash
   # 本地测试
   cd terraform
   terraform init
   terraform plan
   ```

## 📝 注意事项

- 这是一个演示项目，仅用于学习目的
- 生产环境需要更多的安全配置
- ngrok 的免费版本有连接限制
- 记得在完成测试后清理资源

## 🧹 清理

```bash
# 停止 Atlantis
docker-compose down

# 停止 ngrok
# Ctrl+C 在 ngrok 终端

# 删除测试分支
git branch -D test-atlantis
git push origin --delete test-atlantis
```
