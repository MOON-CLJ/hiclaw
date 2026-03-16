# HiClaw 交互式安装记录

> 本文档采用协作模式：AI 给出建议命令，用户确认后执行，过程中逐步完善记录。
>
> **路径约定：**
> - `$HICLAW_SRC` — HiClaw 源码目录（如 `~/dev/hiclaw`）
> - `$CLONE_ROOT` — 克隆依赖项目的父目录（如 `~/dev/`）

**API 配置信息**（由用户提供）：
- Base URL: `https://your-openai-api.example.com/v1`
- Model: `glm-5`
- API Key: [用户保管]

---

## 前置准备：Colima 独立环境（可选）

> 如果你已有 Docker 环境且资源充足（4CPU/8GB+），可跳过此步骤直接使用现有环境。

**用户选择**：方案 1 - 创建独立 HiClaw 环境

### 创建 hiclaw profile

**执行命令：**
```bash
colima start hiclaw --cpu 4 --memory 8 --disk 60 --arch aarch64
```

**执行状态：** ✅ 已完成

**执行时间：** 2026-03-15 16:28 ~ 17:54（约 26 分钟）

**执行结果：**
```
✅ colima [profile=hiclaw] 创建成功

配置：
- CPU: 4 核
- Memory: 8GB
- Disk: 60GB
- Arch: aarch64
- Runtime: Docker
- Socket: unix:///~/.colima/hiclaw/docker.sock

状态：
- VM 运行中（macOS Virtualization.Framework）
- Docker context 已自动切换为 colima-hiclaw
```

### 后续步骤（等待完成后执行）

**待执行命令：**
```bash
# 切换到 HiClaw Docker 环境
docker context use colima-hiclaw

# 验证环境
docker info | grep -i memory
docker ps
```

---

## 安装前检查

### 1.1 检查 Docker 环境

**建议命令：**
```bash
docker version --format 'Docker: {{.Server.Version}}'
docker info 2>/dev/null | grep -i memory
```

**执行状态：** ⬜ 待执行

**执行结果记录：**
```
# [待填写]
```

### 1.2 检查现有安装

**建议命令：**
```bash
docker ps -a | grep hiclaw
ls -la ~/hiclaw-manager.env 2>/dev/null && echo "存在环境文件" || echo "无环境文件"
```

**执行状态：** ⬜ 待执行

**检查结果：**
```
# [待填写]
# - 是否已有容器运行：
# - 是否已有环境文件：
```

---

## 步骤 1：构建镜像

### 构建结果记录

**执行命令：**
```bash
cd $HICLAW_SRC
export HTTPS_PROXY=http://host.lima.internal:1083
export HTTP_PROXY=http://host.lima.internal:1083
make build-openclaw-base build-manager build-worker
```

**执行时间：** 2026-03-15 18:30 ~ 20:05

**执行状态：** ✅ 核心组件构建完成

**构建结果：**
```
✅ hiclaw/openclaw-base:latest    - 本地构建成功（从 GitHub clone johnlanni/openclaw）
✅ hiclaw/manager-agent:latest    - 本地构建成功
✅ hiclaw/worker-agent:latest     - 本地构建成功
⬜ hiclaw/copaw-worker:latest     - 跳过（暂不需要）
```

**镜像大小：**
| 镜像 | 大小 |
|------|------|
| hiclaw/openclaw-base | 4.13GB |
| hiclaw/manager-agent | 4.61GB |
| hiclaw/worker-agent | 4.17GB |

**问题分析：**
- Manager 和 Worker 构建成功，因为它们基于已下载的 openclaw-base 镜像
- CoPaw 构建失败，因为需要从 GitHub 下载 CoPaw 源码
- openclaw-base 未重新构建，使用已缓存的远程镜像

**相关仓库已克隆：**
```
$CLONE_ROOT
├── higress/          # AI Gateway（有 Dockerfile）
├── element-web/      # Matrix Web UI（有 Dockerfile）
├── minio/            # 对象存储（有 Dockerfile）
├── minio-mc/         # MinIO CLI（有 Dockerfile）
└── hiclaw/           # 本项目
```

**详细构建指南：** 见 [local-build-guide.md](./local-build-guide.md)

### 方案选择

**✅ 选定方案：简化本地构建**
- 只构建 HiClaw 核心组件（openclaw-base、manager、worker、CoPaw）
- 基础服务镜像（minio、tuwunel、element-web 等）直接拉取
- 配置 GitHub 代理以支持 OpenClaw 和 CoPaw 源码下载

### 方式 B：使用预构建镜像（跳过构建）

如果不想本地构建，可以直接使用远程镜像：

**建议命令：**
```bash
# 设置使用远程镜像
export HICLAW_REGISTRY=higress-registry.cn-hangzhou.cr.aliyuncs.com
export HICLAW_INSTALL_MANAGER_IMAGE=${HICLAW_REGISTRY}/higress/hiclaw-manager:latest
export HICLAW_INSTALL_WORKER_IMAGE=${HICLAW_REGISTRY}/higress/hiclaw-worker:latest
export HICLAW_INSTALL_COPAW_WORKER_IMAGE=${HICLAW_REGISTRY}/higress/hiclaw-copaw-worker:latest
echo "将使用远程镜像安装"
```

**执行状态：** ⬜ 待执行（如选择方式 B）

---

## 步骤 2：配置环境变量

根据用户的 OpenAI 兼容 API，设置环境变量：

**建议命令：**
```bash
# LLM 配置（OpenAI 兼容模式）
export HICLAW_LLM_PROVIDER="openai-compat"
export HICLAW_OPENAI_BASE_URL="https://your-openai-api.example.com/v1"
export HICLAW_DEFAULT_MODEL="glm-5"

# 提示用户输入 API Key
read -s -p "请输入你的 API Key (AppId): " HICLAW_LLM_API_KEY
echo ""
export HICLAW_LLM_API_KEY

echo "配置完成："
echo "  Base URL: $HICLAW_OPENAI_BASE_URL"
echo "  Model: $HICLAW_DEFAULT_MODEL"
echo "  API Key: ${HICLAW_LLM_API_KEY:0:8}..."
```

**执行状态：** ⬜ 待执行

**执行结果：**
```
# [待填写]
```

---

## 步骤 3：非交互式安装

### 3.1 清理旧安装（如有）

```bash
docker stop hiclaw-manager 2>/dev/null; docker rm hiclaw-manager 2>/dev/null
docker volume rm hiclaw-data 2>/dev/null
rm -f ~/hiclaw-manager.env
rm -rf ~/hiclaw-manager
```

### 3.2 确保 socat 转发（Colima 环境必需）

Colima 的 Docker socket 在 VM 内部，无法通过 `-v` 挂载到容器（详见 [docker-socket-fix.md](./docker-socket-fix.md)）。
需要在 VM 内运行 socat 将 socket 转发为 TCP：

```bash
# 检查 socat 是否已在运行
colima ssh --profile hiclaw -- pgrep -a socat

# 如果没有运行，启动它
colima ssh --profile hiclaw -- sudo nohup socat \
  TCP4-LISTEN:2375,reuseaddr,fork,range=172.17.0.0/24 \
  UNIX-CONNECT:/var/run/docker.sock '>/tmp/socat.log' '2>&1' '&'
```

### 3.3 执行安装

> **注意：** `make install` 硬编码了 `HICLAW_LLM_PROVIDER=qwen`（阿里云通义千问）。
> 使用其他 OpenAI 兼容 API 时，需要直接调用安装脚本并传入自定义配置。

**方式 A：使用默认 qwen Provider（适合阿里云用户）**
```bash
cd $HICLAW_SRC
HICLAW_LLM_API_KEY="sk-xxx" make install
```

**方式 B：使用 OpenAI 兼容 API（本环境使用的方式）**
```bash
cd $HICLAW_SRC
HICLAW_NON_INTERACTIVE=1 \
HICLAW_VERSION=latest \
HICLAW_MOUNT_SOCKET=1 \
HICLAW_LLM_PROVIDER=openai-compat \
HICLAW_OPENAI_BASE_URL="https://your-openai-api.example.com/v1" \
HICLAW_DEFAULT_MODEL=glm-5 \
HICLAW_LLM_API_KEY="Bearer xxx" \
HICLAW_ADMIN_USER=your-username \
HICLAW_ADMIN_PASSWORD=your-password \
HICLAW_HOST_SHARE_DIR="$HOME" \
HICLAW_INSTALL_MANAGER_IMAGE=hiclaw/manager-agent:latest \
HICLAW_INSTALL_WORKER_IMAGE=hiclaw/worker-agent:latest \
HICLAW_INSTALL_COPAW_WORKER_IMAGE=hiclaw/copaw-worker:latest \
bash ./install/hiclaw-install.sh manager
```

安装脚本会输出 `未找到容器运行时 socket` 的警告——这在 Colima 环境下是预期行为，不影响安装完成。

**预计耗时：** 1-2 分钟（本地镜像），3-5 分钟（首次拉取远程镜像）

### 3.4 添加 DOCKER_HOST 启用 Worker 创建能力（Colima 环境必需）

安装脚本不会自动设置 `DOCKER_HOST`，需要重建容器补上这个环境变量，
使 Manager 能通过 socat TCP 转发调用 Docker API 创建 Worker 容器。

> **镜像版本注意：** 如果当前镜像中的 `container-api.sh` 尚未包含 TCP 模式支持（即本地代码修改未构建进镜像），
> 需要额外挂载本地修改后的文件。下方命令已包含此挂载。镜像重新构建后可去掉该行。

```bash
# 停掉安装脚本创建的容器
docker stop hiclaw-manager && docker rm hiclaw-manager

# 重建，增加 DOCKER_HOST 环境变量
# 注意：docker run 中 ~ 不会被展开，必须用 $HOME
docker run -d \
  --name hiclaw-manager \
  --env-file "$HOME/hiclaw-manager.env" \
  -e DOCKER_HOST=tcp://172.17.0.1:2375 \
  -e HOME=/root/manager-workspace \
  -w /root/manager-workspace \
  -e HOST_ORIGINAL_HOME="$HOME" \
  -e TZ=Asia/Shanghai \
  -v hiclaw-data:/data \
  -v "$HOME/hiclaw-manager:/root/manager-workspace" \
  -v "$HOME:/host-share" \
  -v "$HOME/dev/aitmp/hiclaw/manager/scripts/lib/container-api.sh:/opt/hiclaw/scripts/lib/container-api.sh:ro" \
  -p 127.0.0.1:18080:8080 \
  -p 127.0.0.1:18001:8001 \
  -p 127.0.0.1:18088:8088 \
  -p 127.0.0.1:18888:18888 \
  --restart unless-stopped \
  hiclaw/manager-agent:latest
```

> 非 Colima 环境（Linux 原生 Docker、Docker Desktop）不需要这一步，安装脚本会自动挂载 socket。

---

## 步骤 4：验证安装

### 4.1 检查容器状态

```bash
docker ps | grep hiclaw
docker logs hiclaw-manager --tail 20
```

**预期结果：**
- 容器状态 `Up`，端口映射 `18080->8080, 18001->8001, 18088->8088, 18888->18888`
- 日志中出现 `Listening on [0.0.0.0:6167]`（tuwunel）和 `gateway listening`（OpenClaw）

### 4.2 检查 Container runtime（Colima 环境）

```bash
docker exec hiclaw-manager bash -c \
  'source /opt/hiclaw/scripts/lib/container-api.sh && container_api_available && echo "API 可达" || echo "API 不可达"'
```

**预期结果：** 完成步骤 3.4 后应输出 `API 可达`。如果输出 `API 不可达`，检查 socat 是否在运行、DOCKER_HOST 环境变量是否正确设置。

### 4.3 测试 LLM API 连通性

```bash
# 注意：必须带正确的 Host header（Higress 路由按域名匹配）
# 认证使用 HICLAW_MANAGER_GATEWAY_KEY 作为 Bearer token
GATEWAY_KEY=$(grep HICLAW_MANAGER_GATEWAY_KEY ~/hiclaw-manager.env | cut -d= -f2)
curl -s http://127.0.0.1:18080/v1/chat/completions \
  -H "Host: aigw-local.hiclaw.io" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${GATEWAY_KEY}" \
  -d '{
    "model": "glm-5",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

**预期结果：** 返回 JSON 响应包含 `choices`。如果返回 404，说明缺少 Host header（见故障排查问题 3）。

### 4.4 访问 Element Web

浏览器打开 `http://127.0.0.1:18088`，使用 `~/hiclaw-manager.env` 中的 `HICLAW_ADMIN_USER` / `HICLAW_ADMIN_PASSWORD` 登录，确认能看到 "HiClaw Manager" 房间。

---

## 步骤 5：创建第一个 Worker（可选）

在 Element Web 中，进入 "HiClaw Manager" 房间，发送：

```
创建一个 Worker 叫 alice
```

**或者使用命令行方式：**

```bash
make replay TASK="创建一个 Worker 叫 alice"
```

**执行状态：** ⬜ 待执行

---

## 安装后信息汇总

| 项目 | 值 |
|------|-----|
| Element Web 地址 | `http://127.0.0.1:18088` |
| Higress 控制台 | `http://127.0.0.1:18001` |
| OpenClaw 控制台 | `http://127.0.0.1:18888` |
| 管理员账号 | `[从 ~/hiclaw-manager.env 查看]` |
| 管理员密码 | `[从 ~/hiclaw-manager.env 查看]` |
| 环境文件 | `~/hiclaw-manager.env` |
| 数据卷 | `hiclaw-data` |
| 工作空间 | `~/hiclaw-manager` |
| Docker 连接方式 | 标准安装无 socket；Colima 需 socat TCP 转发（`DOCKER_HOST=tcp://172.17.0.1:2375`） |

---

## 故障排查记录

### 问题 1：tuwunel 启动失败，manager-agent 循环崩溃

**现象：**
```
# tuwunel 报错（FATAL 状态）：
Error: Registration token was specified but is empty ("") config=registration_token

# manager-agent 每 2 分钟重启：
[hiclaw] ERROR: Tuwunel did not become available within 120s
```

**原因：**
容器缺少 `HICLAW_REGISTRATION_TOKEN`、`HICLAW_MANAGER_PASSWORD`、`HICLAW_MANAGER_GATEWAY_KEY`
三个环境变量。虽然 `~/hiclaw-manager.env` 文件中有值，但安装脚本 `docker run --env-file`
未能正确加载（可能是安装时 env 文件写入顺序问题）。

**解决方式：**
停止并删除容器，重新 `docker run --env-file ~/hiclaw-manager.env` 确保 env 文件正确加载。

### 问题 2：Docker socket 无法挂载（Colima virtiofs 限制）

**现象：**
```
⚠️ 未检测到容器运行时 Socket
```

**解决方式：**
1. 在 Colima VM 内启动 socat 转发（详见 [docker-socket-fix.md](./docker-socket-fix.md)）
2. 启动容器时添加 `-e DOCKER_HOST=tcp://172.17.0.1:2375`（`container-api.sh` 已内建 TCP 模式支持，检测到 `DOCKER_HOST` 环境变量后自动切换）

### 问题 3：Higress API 测试返回 404

**现象：**
```bash
curl http://127.0.0.1:18080/v1/chat/completions  # -> 404
```

**原因：**
Higress 路由按域名匹配，AI Gateway 路由绑定到 `aigw-local.hiclaw.io`。
不带 Host header 的请求匹配不到路由，返回 Higress 控制台的 404。

**解决方式：**
请求时必须携带 `-H "Host: aigw-local.hiclaw.io"` header。

---

## 后续操作

### VM 重启后恢复 socat

socat 是后台进程，Colima VM 重启后需要重新启动：

```bash
colima ssh --profile hiclaw -- bash <<'EOF'
sudo nohup socat TCP4-LISTEN:2375,reuseaddr,fork,range=172.17.0.0/24 \
  UNIX-CONNECT:/var/run/docker.sock > /tmp/socat.log 2>&1 &
EOF
```

### 卸载
```bash
make uninstall
```

### 查看日志
```bash
# Manager 容器日志
docker logs hiclaw-manager

# Agent 详细日志
docker exec hiclaw-manager cat /var/log/hiclaw/manager-agent.log

# Tuwunel 日志
docker exec hiclaw-manager cat /var/log/hiclaw/tuwunel.log
```

### 重新配置
编辑 `~/hiclaw-manager.env` 后重启：
```bash
docker restart hiclaw-manager
```

---

**文档更新记录：**
- 2026-03-15: 创建文档，记录 API 配置、Colima 环境创建、镜像构建
- 2026-03-15: 记录安装过程、Docker socket 问题、socat 方案、故障排查
- 2026-03-16: 重写步骤 3 为可复现的安装指南（清理→socat→安装→补 DOCKER_HOST），去除试错历史；步骤 4 改为验证命令指南；修正 LLM Provider 值（openai-compatible → openai-compat）
