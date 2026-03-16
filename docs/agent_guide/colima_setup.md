# HiClaw + Colima 环境准备指南

本文档介绍如何在 macOS 上使用 Colima 运行 HiClaw，包括独立环境和共享环境的对比、配置步骤和常见问题。

---

## 1. Colima 简介

[Colima](https://github.com/abiosoft/colima) 是 macOS 上 Docker Desktop 的轻量级替代品，使用 Lima VM 运行容器。

**特点：**
- 资源占用低（比 Docker Desktop 轻量）
- 支持 x86_64 和 ARM64 架构
- 可以通过 Homebrew 安装
- 支持多 profile（类似多环境）

---

## 2. 环境方案对比

### 2.1 方案对比表

| 方面 | 默认环境（共享） | 独立 HiClaw 环境 |
|------|------------------|------------------|
| **资源分配** | 与所有项目共享，HiClaw 可能内存不够 | 固定 8GB+，保证 HiClaw 运行 |
| **端口占用** | 可能与其他项目冲突 (18080/18001/18088) | 独立网络栈，无端口冲突 |
| **数据隔离** | Docker 卷、镜像、网络混杂 | 完全独立，便于管理 |
| **清理重置** | 需要逐个删除容器/镜像 | `colima delete hiclaw` 一键清理 |
| **切换操作** | 直接使用 `docker` 命令 | 需要 `docker context use` 切换 |
| **磁盘占用** | 与其他项目共用磁盘 | 单独磁盘配额，不互相影响 |
| **团队协作** | 难以复现环境 | 可导出 profile 配置分享给同事 |

### 2.2 默认环境的问题场景

```
场景 1：资源不足
- 默认 Colima 配置：2 CPU / 4GB 内存
- HiClaw 需要 8GB 内存 → Worker 创建失败或 OOM

场景 2：端口冲突
- 其他项目已占用 18080 → HiClaw Higress 网关启动失败
- 需要手动修改端口配置

场景 3：环境污染
- HiClaw 安装 5-10 个镜像
- 与其他项目镜像混在一起，难以清理

场景 4：问题排查困难
- HiClaw 出问题，不确定是 HiClaw 本身还是其他项目影响
```

### 2.3 独立环境的优势

```
优势 1：资源保证
- 固定分配 4 CPU / 8GB 内存
- HiClaw Manager + Worker 都能正常运行

优势 2：完全隔离
- 独立的 Docker 守护进程
- 独立的网络栈（端口不冲突）
- 独立的存储卷

优势 3：快速重置
- 实验失败：colima stop hiclaw && colima start hiclaw
- 彻底清理：colima delete hiclaw（一键删除所有数据）

优势 4：便于团队协作
- 将 hiclaw profile 分享给同事
- 保证环境一致性
```

### 2.4 推荐方案

| 场景 | 推荐方案 |
|------|----------|
| **个人开发，资源充足（16GB+）** | 独立环境（避免污染主环境） |
| **个人开发，资源紧张（8GB）** | 调整默认环境到 6GB（勉强运行） |
| **团队协作/需要可复现** | 独立环境（必须） |
| **快速体验/测试** | 独立环境（测试完删除） |
| **长期运行生产环境** | 独立环境（便于维护） |

**结论：推荐使用独立 HiClaw 环境**

---

## 3. 独立环境配置步骤

### 3.1 安装 Colima（如未安装）

```bash
# 使用 Homebrew 安装
brew install colima

# 验证安装
colima version
```

### 3.2 创建 HiClaw 专用环境

```bash
# 创建名为 "hiclaw" 的 profile
# 配置：4 CPU, 8GB 内存, 60GB 磁盘

colima start hiclaw \
  --cpu 4 \
  --memory 8 \
  --disk 60 \
  --arch aarch64  # 根据你的 Mac 调整：aarch64 (ARM) 或 x86_64

# 或使用模板方式（推荐）
colima template --profile hiclaw \
  --cpu 4 \
  --memory 8 \
  --disk 60 \
  --arch aarch64

colima start hiclaw
```

**参数说明：**
| 参数 | 值 | 说明 |
|------|-----|------|
| `--cpu 4` | 4 核 | HiClaw 推荐配置 |
| `--memory 8` | 8GB | 保证 Manager + Worker 运行 |
| `--disk 60` | 60GB | 镜像和容器数据存储 |
| `--arch` | aarch64/x86_64 | 根据 Mac 芯片选择 |

### 3.3 切换到 HiClaw 环境

```bash
# 方式 1：切换 Docker context（推荐）
docker context use colima-hiclaw

# 验证
docker ps
docker info | grep "Name:"

# 方式 2：临时指定（不切换全局 context）
export DOCKER_HOST="unix://${HOME}/.colima/hiclaw/docker.sock"
docker ps

# 方式 3：每个命令指定（脚本中使用）
DOCKER_HOST="unix://${HOME}/.colima/hiclaw/docker.sock" docker ps
```

### 3.4 验证环境

```bash
# 检查资源分配
docker info | grep -i memory
docker info | grep -i cpu

# 检查镜像仓库（应该是空的，全新环境）
docker images

# 测试运行容器
docker run --rm hello-world
```

---

## 4. 日常使用命令

### 4.1 环境切换速查表

| 操作 | 命令 |
|------|------|
| **启动 HiClaw 环境** | `colima start hiclaw` |
| **停止 HiClaw 环境** | `colima stop hiclaw` |
| **重启 HiClaw 环境** | `colima restart hiclaw` |
| **删除 HiClaw 环境** | `colima delete hiclaw` |
| **查看状态** | `colima status hiclaw` |
| **查看所有 profile** | `colima ls` |
| **切换到 HiClaw** | `docker context use colima-hiclaw` |
| **切换到默认** | `docker context use colima` |
| **查看当前 context** | `docker context ls` |

### 4.2 工作流示例

```bash
# === 日常使用流程 ===

# 1. 启动 Colima
$ colima start hiclaw
INFO[0000] starting colima [profile=hiclaw]
INFO[0004] done

# 2. 切换到 HiClaw Docker 环境
$ docker context use colima-hiclaw
colima-hiclaw

# 3. 验证环境
$ docker ps
CONTAINER ID   IMAGE   COMMAND   CREATED   STATUS   PORTS   NAMES

# 4. 运行 HiClaw 安装
$ cd ~/dev/hiclaw
$ make install
...

# 5. 使用 HiClaw...

# 6. 停止环境（节省资源）
$ colima stop hiclaw
INFO[0000] stopping colima [profile=hiclaw]
INFO[0003] done
```

---

## 5. 常见问题

### 5.1 内存不足

**症状：**
```
Worker 创建失败
docker: Error response from daemon: OOMKilled
```

**解决：**
```bash
# 停止并调整内存
colima stop hiclaw
colima start hiclaw --memory 8

# 或修改模板
colima template --profile hiclaw --memory 8
colima start hiclaw
```

### 5.2 磁盘空间不足

**症状：**
```
no space left on device
```

**解决：**
```bash
# 查看磁盘使用
colima ssh hiclaw -- df -h

# 清理无用镜像
docker system prune -a

# 或扩容
colima stop hiclaw
colima start hiclaw --disk 100
```

### 5.3 端口无法访问

**症状：**
浏览器访问 `127.0.0.1:18088` 失败

**原因：**
Colima 默认只绑定到 VM 内部，需要配置端口转发

**解决：**
```bash
# 停止并重新启动，添加端口转发
colima stop hiclaw

# 编辑配置添加端口转发
colima template --profile hiclaw --cpu 4 --memory 8

# 或在启动时指定
colima start hiclaw --port 18080:18080 --port 18001:18001 --port 18088:18088
```

### 5.4 Context 切换混乱

**症状：**
```
Cannot connect to the Docker daemon
```

**解决：**
```bash
# 查看所有 context
docker context ls

# 切换到正确的
docker context use colima-hiclaw

# 或手动指定 socket
export DOCKER_HOST="unix://${HOME}/.colima/hiclaw/docker.sock"
```

### 5.5 彻底重置 HiClaw

```bash
# 删除 HiClaw 容器
docker rm -f hiclaw-manager
docker ps -a | grep hiclaw-worker | awk '{print $1}' | xargs docker rm -f

# 删除数据卷
docker volume rm hiclaw-data

# 删除环境文件
rm ~/hiclaw-manager.env
rm -rf ~/hiclaw-manager

# 如果需要，删除整个 Colima 环境
colima delete hiclaw
```

---

## 6. 高级配置

### 6.1 自动启动

```bash
# 设置开机自动启动
colima start hiclaw --foreground

# 或使用 launchd（macOS）
brew services start colima
```

### 6.2 多架构支持

如果你的 Mac 是 ARM（M1/M2/M3），但需要运行 x86 镜像：

```bash
colima start hiclaw --arch x86_64

# 或使用 Rosetta 2（更快）
colima start hiclaw --arch aarch64 --vm-type vz --rosetta
```

### 6.3 挂载主机目录

```bash
# 编辑 Colima 配置，添加目录挂载
colima template --profile hiclaw

# 修改 mounts 部分
# mounts:
#   - location: ~/hiclaw-data
#     writable: true
```

---

## 7. 与 Docker Desktop 对比

| 特性 | Colima | Docker Desktop |
|------|--------|----------------|
| 资源占用 | 低（几百 MB） | 高（2-3GB） |
| 启动速度 | 快 | 慢 |
| 多环境支持 | 原生支持 profile | 需要 Docker context |
| 图形界面 | 无 | 有 |
| Kubernetes | 内置支持 | 内置支持 |
| 价格 | 免费 | 企业收费 |

**推荐：** 对于 HiClaw 这类需要多环境隔离的场景，Colima 更合适。

---

## 8. 参考链接

- [Colima GitHub](https://github.com/abiosoft/colima)
- [Colima 官方文档](https://github.com/abiosoft/colima/blob/main/docs/FAQ.md)
- [HiClaw 安装指南](./installation.md)
- [HiClaw 架构说明](../architecture.md)

---

**文档更新记录：**
- 2026-03-15: 创建文档，对比独立环境和共享环境
