# HiClaw 安装过程实际执行动作

本文档详细说明 `make install-interactive` 或 `bash install/hiclaw-install.sh` 执行时，系统实际会进行的操作。

## 执行流程概览

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   1. 环境检查    │ -> │  2. 交互式配置   │ -> │  3. 镜像准备    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        |
┌─────────────────┐    ┌─────────────────┐    ┌───────┘
│ 6. 服务就绪检测  │ <- │ 5. 启动容器      │ <- │ 4. 资源创建     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         |
┌────────┘
│ 7. 完成输出
▼
```

---

## 1. 环境检查

### 1.1 容器运行时检测
- 检测 Docker/Podman 是否已安装并运行
- 检查 Docker Socket 是否可访问（用于 Manager 自动创建 Worker）
- 如果未检测到 Socket，提示用户确认是否继续（将无法自动创建 Worker）

### 1.2 时区和语言检测
- 自动检测系统时区（用于选择镜像仓库区域）
- 根据时区自动选择语言：
  - 中国时区（Asia/Shanghai 等）→ 中文
  - 其他时区 → 英文

### 1.3 现有安装检测
- 检查是否存在已有的 Manager 安装
- 如果发现已有安装，提供选项：
  - **就地升级**：保留数据、工作空间、env 文件，只更新容器
  - **全新重装**：删除所有数据，重新开始
  - **取消安装**

---

## 2. 交互式配置

### 2.1 选择安装模式
| 模式 | 说明 |
|------|------|
| **快速开始** | 使用阿里云百炼预配置，只需输入 API Key |
| **手动配置** | 自定义 LLM 提供商、模型、端口等所有选项 |

### 2.2 LLM 配置（关键步骤）

#### 快速开始模式
- 默认使用 **阿里云百炼**
- 默认模型：`qwen3.5-plus`
- 需要输入：API Key
- 可选：是否使用 Coding Plan 接口

#### 手动配置模式
**选择提供商：**
1. **阿里云百炼** - 推荐中国用户
2. **OpenAI 兼容 API** - 支持自定义 Base URL

**OpenAI 兼容格式配置项：**
| 配置项 | 说明 | 示例 |
|--------|------|------|
| `Base URL` | API 端点地址，**必须包含 `/v1`** | `https://api.openai.com/v1` |
| `API Key` | 认证密钥 | `sk-xxx...` |
| `Model` | 默认模型名称 | `gpt-4` / `deepseek-chat` |

**API 连通性测试：**
- 安装脚本会发送测试请求验证配置
- 如果失败，会显示 HTTP 状态码和错误响应

### 2.3 网络配置

**端口映射（主机:容器）：**
| 服务 | 主机端口（默认） | 容器端口 | 说明 |
|------|-----------------|----------|------|
| Higress AI 网关 | 18080 | 8080 | LLM 代理入口 |
| Higress 控制台 | 18001 | 8001 | 网关管理界面 |
| Element Web | 18088 | 8088 | Matrix 客户端 |
| MinIO 控制台 | 19001 | 9001 | 文件存储管理 |

**网络访问模式：**
- **仅本地访问**：绑定 `127.0.0.1`，只允许本机访问
- **允许外部访问**：绑定 `0.0.0.0`，允许局域网/公网访问

### 2.4 其他配置

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| Matrix 域名 | `matrix-local.hiclaw.io:18080` | 用于 Matrix 客户端连接 |
| 数据持久化 | `hiclaw-data`（Docker 卷）| 存储 Matrix、MinIO、Higress 数据 |
| 工作空间目录 | `~/hiclaw-manager` | Manager Agent 的工作目录 |
| GitHub 集成 | 无 | 可选配置 GitHub PAT 和 MCP 服务 |
| Docker Socket 挂载 | 启用 | 允许 Manager 创建 Worker 容器 |

### 2.5 生成环境文件

所有配置会被写入 `~/hiclaw-manager.env`：

```bash
# LLM 配置
HICLAW_LLM_API_KEY=sk-xxx
HICLAW_LLM_PROVIDER=qwen  # 或 openai-compatible
HICLAW_OPENAI_BASE_URL=https://api.xxx.com/v1  # OpenAI 兼容模式
HICLAW_DEFAULT_MODEL=qwen3.5-plus

# 端口配置
HICLAW_PORT_GATEWAY=18080
HICLAW_PORT_CONSOLE=18001
HICLAW_PORT_ELEMENT_WEB=18088

# 数据配置
HICLAW_DATA_DIR=hiclaw-data
HICLAW_WORKSPACE_DIR=/Users/xxx/hiclaw-manager
HICLAW_MATRIX_DOMAIN=matrix-local.hiclaw.io:18080

# 管理员账号
HICLAW_ADMIN_USER=admin
HICLAW_ADMIN_PASSWORD=auto-generated

# 镜像配置
HICLAW_VERSION=latest
HICLAW_REGISTRY=higress-registry.cn-hangzhou.cr.aliyuncs.com
```

---

## 3. 镜像准备

### 3.1 镜像检测与拉取

**本地构建模式**（使用 `make install`）：
- 使用本地构建的镜像：`hiclaw/manager-agent:latest`
- 跳过远程拉取

**远程拉取模式**（使用在线安装脚本）：
- Manager 镜像：`higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/hiclaw-manager:latest`
- Worker 镜像：`higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/hiclaw-worker:latest`
- CoPaw Worker 镜像：`higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/hiclaw-copaw-worker:latest`

### 3.2 镜像仓库选择（根据时区自动选择）
| 区域 | 仓库地址 |
|------|----------|
| 中国（默认）| `higress-registry.cn-hangzhou.cr.aliyuncs.com` |
| 北美 | `higress-registry.us-west-1.cr.aliyuncs.com` |
| 东南亚 | `higress-registry.ap-southeast-7.cr.aliyuncs.com` |

---

## 4. 资源创建

### 4.1 创建 Docker 数据卷
```bash
docker volume create hiclaw-data
```

**数据卷用途：**
- Matrix 服务器数据（用户、房间、消息）
- MinIO 文件存储数据
- Higress 网关配置

### 4.2 创建工作空间目录
```bash
mkdir -p ~/hiclaw-manager
```

**工作空间内容：**
- Manager Agent 运行时代码
- Agent 日志
- 临时文件
- Worker 配置文件

---

## 5. 启动 Manager 容器

### 5.1 停止并移除现有容器（升级场景）
```bash
docker stop hiclaw-manager 2>/dev/null
docker rm hiclaw-manager 2>/dev/null
```

### 5.2 执行 docker run

**实际执行的命令（简化）：**

```bash
docker run -d \
  --name hiclaw-manager \
  --privileged \
  --restart unless-stopped \
  -p 127.0.0.1:18080:8080 \      # Higress 网关
  -p 127.0.0.1:18001:8001 \      # Higress 控制台
  -p 127.0.0.1:18088:8088 \      # Element Web
  -p 127.0.0.1:19000:9000 \      # MinIO API
  -p 127.0.0.1:19001:9001 \      # MinIO 控制台
  -v hiclaw-data:/data \         # 数据持久化
  -v ~/hiclaw-manager:/root/manager-workspace \  # 工作空间
  -v /var/run/docker.sock:/var/run/docker.sock \ # Docker Socket（可选）
  -e HICLAW_LLM_API_KEY=xxx \    # LLM 配置
  -e HICLAW_LLM_PROVIDER=qwen \
  -e HICLAW_DEFAULT_MODEL=qwen3.5-plus \
  -e HICLAW_MATRIX_DOMAIN=matrix-local.hiclaw.io:18080 \
  higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/hiclaw-manager:latest
```

### 5.3 容器内启动的服务

**使用 supervisord 管理多个进程：**

| 服务 | 容器内端口 | 说明 |
|------|-----------|------|
| **Tuwunel** | 6167 | Matrix  homeserver（替代 Synapse）|
| **MinIO** | 9000/9001 | S3 兼容的对象存储 |
| **Higress Gateway** | 8080 | AI 网关，LLM 代理 |
| **Higress Console** | 8001 | 网关管理界面 |
| **Element Web** | 8088 | Matrix Web 客户端 |
| **Manager Agent** | - | OpenClaw/CoPaw Agent（通过 Matrix 通信）|

---

## 6. 服务就绪检测

### 6.1 等待 Matrix 服务就绪
**检测端点：** `http://127.0.0.1:6167/_tuwunel/server_version`
- 超时：60 秒
- 轮询间隔：2 秒

### 6.2 等待 Manager Agent 就绪
**检测方式：**
- 检查 Agent 日志文件是否存在
- 等待 Agent 初始化完成（约 60 秒）
- 超时：300 秒

### 6.3 服务健康检查

| 服务 | 检测端点 |
|------|----------|
| Matrix | `/_matrix/client/versions` |
| MinIO | `/minio/health/live` |
| Higress Console | `/` |

---

## 7. 完成输出

安装完成后，显示以下信息：

```
========================================
✅ HiClaw Manager 安装完成！
========================================

📱 访问地址：
    http://127.0.0.1:18088/#/login

👤 登录信息：
    用户名: admin
    密码:   xxxxxxxx（随机生成）

🔧 管理控制台：
    http://127.0.0.1:18001
    用户名: admin
    密码:   xxxxxxxx（同上）

💡 使用提示：
    1. 在 Element Web 中登录
    2. 找到 "HiClaw Manager" 房间
    3. 发送消息："创建一个 Worker 叫 alice"

📁 配置文件：
    ~/hiclaw-manager.env

📝 查看日志：
    docker logs hiclaw-manager
    docker exec hiclaw-manager cat /var/log/hiclaw/manager-agent.log
```

---

## 常见问题

### 安装失败怎么办？

1. **查看安装日志**
   ```bash
   cat ~/hiclaw-install.log
   ```

2. **查看容器日志**
   ```bash
   docker logs hiclaw-manager
   ```

3. **查看 Agent 日志**
   ```bash
   docker exec hiclaw-manager cat /var/log/hiclaw/manager-agent.log
   ```

### 如何重新安装？

```bash
# 卸载（保留数据）
make uninstall

# 或者全新重装（删除所有数据）
make uninstall
# 手动删除 Docker 卷: docker volume rm hiclaw-data
# 手动删除工作空间: rm -rf ~/hiclaw-manager
# 手动删除 env 文件: rm ~/hiclaw-manager.env

# 重新安装
make install-interactive
```

### 如何升级？

直接运行安装脚本，选择**就地升级**：
```bash
make install-interactive
# 或
bash <(curl -sSL https://higress.ai/hiclaw/install.sh)
```

---

## 相关文档

- [安装指南](../quickstart.md) - 快速开始步骤
- [架构说明](../architecture.md) - 系统架构详解
- [Manager 配置](../manager-guide.md) - 高级配置选项
- [FAQ](../faq.md) - 常见问题解答
