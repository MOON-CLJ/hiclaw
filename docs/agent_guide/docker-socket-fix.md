# Colima + Virtiofs Docker Socket 解决方案

## 问题

### 背景

HiClaw 安装脚本（`detect_socket`）检测 `/run/podman/podman.sock` 或 `/var/run/docker.sock`（Podman 优先），
找到后通过 `-v` 挂载到 Manager 容器内，使 Manager 能直接调用 Docker API 创建 Worker 容器。

这个设计适用于：
- **Linux 原生 Docker/Podman**：socket 在标准路径，可直接挂载
- **Docker Desktop (macOS)**：在 `/var/run/docker.sock` 维护符号链接，也可正常挂载

### Colima 下的问题

Colima 的 socket 不在标准路径，而是在 `~/.colima/<profile>/docker.sock`：

```
$ docker context ls
colima-hiclaw *   unix:///Users/xxx/.colima/hiclaw/docker.sock
default           unix:///var/run/docker.sock          # 不存在
```

即使补上 Colima 的 socket 路径也无法挂载，因为存在两层障碍：

1. **virtiofs 不支持 Unix socket 文件共享** — Colima 默认使用 virtiofs 将 macOS 目录共享到 VM，但 virtiofs 协议无法传递 socket 文件。VM 内对共享的 socket 执行任何操作均报 `Operation not supported`
2. **VM 内的真实 socket 不可挂载** — Docker daemon 的 `/var/run/docker.sock` 在 VM 内部，不在 virtiofs 共享范围内，容器无法通过 `-v` 直接访问

## 解决方案：使用 socat 转发（不修改 Docker 配置）

在 VM 内运行 socat，将 Docker Unix socket 转发为 TCP，供容器通过 `172.17.0.1:2375` 访问。

### 步骤

```bash
# 1. 进入 VM
colima ssh --profile hiclaw

# 2. 启动 socat（后台运行）
#    range=172.17.0.0/24 限制只有容器网络内的客户端才能连接
sudo nohup socat TCP4-LISTEN:2375,reuseaddr,fork,range=172.17.0.0/24 \
  UNIX-CONNECT:/var/run/docker.sock > /tmp/socat.log 2>&1 &

# 3. 退出 VM
exit
```

### 启动 Manager 容器

启动时通过 `DOCKER_HOST` 环境变量指定 TCP 连接（不需要挂载 socket 文件）：

```bash
docker run -d \
  --name hiclaw-manager \
  -e DOCKER_HOST=tcp://172.17.0.1:2375 \
  -v hiclaw-data:/data \
  -v ~/hiclaw-manager:/root/manager-workspace \
  -p 127.0.0.1:18080:8080 \
  -p 127.0.0.1:18001:8001 \
  -p 127.0.0.1:18088:18888 \
  -p 127.0.0.1:18888:18888 \
  --env-file ~/hiclaw-manager.env \
  hiclaw/manager-agent:latest
```

### 验证

从 Manager 容器内确认 Docker API 可达：

```bash
docker exec hiclaw-manager curl -s http://172.17.0.1:2375/version
```

### 安全性

```
172.17.0.1:2375
      ↑
      ├── VM 外部无法访问（192.168.x.x 不通）
      ├── macOS 宿主机无法访问
      ├── range=172.17.0.0/24 限制只有容器网络客户端可连
      └── 不修改 Docker daemon 配置 ✅
```

### 注意事项

- socat 通过 `nohup &` 后台运行，**VM 重启后需要重新启动**
- 如需持久化，可在 VM 内创建 systemd service
