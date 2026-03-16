# HiClaw 完全本地构建指南

本文档指导如何完全从源码构建 HiClaw 及其所有依赖镜像。

> **路径约定：**
> - `$HICLAW_SRC` — HiClaw 源码目录（如 `~/dev/hiclaw`）
> - `$CLONE_ROOT` — 克隆依赖项目的父目录（如 `~/dev/`）

## 1. 镜像依赖关系

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              外部基础镜像（可选本地构建）                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐            │
│  │ higress/all-in-one│  │ higress/tuwunel   │  │ higress/minio     │            │
│  │ (AI Gateway)     │  │ (Matrix Server)   │  │ (对象存储)         │            │
│  │ → 复杂，建议拉取  │  │ → 可本地构建      │  │ → 可本地构建      │            │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘            │
│  ┌──────────────────┐  ┌──────────────────┐                                 │
│  │ higress/mc        │  │ higress/element-web│                                │
│  │ (MinIO CLI)      │  │ (Web UI)          │                                │
│  │ → 可本地构建      │  │ → 可本地构建      │                                │
│  └──────────────────┘  └──────────────────┘                                 │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HiClaw 核心（必须本地构建）                     │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │ openclaw-base                                                │            │
│  │ 基于: higress/all-in-one + Node.js + OpenClaw 源码           │            │
│  │ 需要: 从 GitHub clone johnlanni/openclaw                     │            │
│  └───────────────────────┬─────────────────────────────────────┘            │
│                          │                                                  │
│         ┌────────────────┼────────────────┐                                 │
│         │                │                │                                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐                         │
│  │   manager   │  │   worker    │  │ copaw-worker│                         │
│  │  (管理节点)  │  │  (工作节点)  │  │ (轻量节点)   │                         │
│  └─────────────┘  └─────────────┘  └─────────────┘                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 2. 已克隆的仓库

当前已克隆到 `$CLONE_ROOT`：

| 仓库 | 路径 | 用途 | Dockerfile |
|------|------|------|------------|
| higress | `higress/` | AI Gateway | `docker/Dockerfile.higress` |
| element-web | `element-web/` | Matrix Web UI | `apps/web/Dockerfile` |
| minio | `minio/` | 对象存储 | `Dockerfile` |
| minio-mc | `minio-mc/` | MinIO CLI | `Dockerfile` |

**缺失仓库：**
- tuwunel (Matrix Server) - 需要查找正确仓库地址

## 3. 本地构建步骤

### 3.1 设置代理（如果需要）

```bash
export HTTPS_PROXY=http://127.0.0.1:1083
export HTTP_PROXY=http://127.0.0.1:1083
```

### 3.2 构建 MinIO 镜像

**分析：** MinIO 的 Dockerfile 只是复制预编译二进制文件，需要先从源码编译。

```bash
cd $CLONE_ROOT/minio

# 查看 Dockerfile
# 注意：这个 Dockerfile 需要预编译的二进制文件
# 方式1：使用官方构建脚本
make docker

# 方式2：直接拉取（如果本地构建太复杂）
# docker pull minio/minio:latest
# docker tag minio/minio:latest higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/minio:20260216
```

### 3.3 构建 MinIO mc 镜像

**分析：** mc 的 Dockerfile 使用多阶段构建，从 Go 源码编译。

```bash
cd $CLONE_ROOT/minio-mc

# 构建
docker build -t minio-mc:local .

# 打标签
docker tag minio-mc:local higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/mc:20260216
```

### 3.4 构建 Element Web 镜像

```bash
cd $CLONE_ROOT/element-web

# 查看 Dockerfile
cat apps/web/Dockerfile

# 构建（需要 Node.js 环境）
# 注意：Element Web 构建复杂，可能需要特定配置
docker build -f apps/web/Dockerfile -t element-web:local .

# 打标签
docker tag element-web:local higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/element-web:20260216
```

### 3.5 构建 Higress all-in-one（可选，复杂）

**注意：** Higress all-in-one 构建非常复杂，涉及 Envoy、Wasm 插件等。
建议先查看官方构建文档：

```bash
cd $CLONE_ROOT/higress

# 查看 Makefile
make help

# 构建（可能需要大量依赖）
# make docker-build

# 更简单的方式：直接拉取
docker pull higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/all-in-one:sha-d32debd
```

### 3.6 构建 HiClaw openclaw-base

```bash
cd $HICLAW_SRC

# 设置代理（如果需要访问 GitHub）
export HTTPS_PROXY=http://127.0.0.1:1083
export HTTP_PROXY=http://127.0.0.1:1083

# 构建 openclaw-base（这会从 GitHub clone OpenClaw）
make build-openclaw-base

# 如果 GitHub 访问失败，可以手动克隆后再构建
```

### 3.7 构建 HiClaw Manager、Worker、CoPaw

```bash
cd $HICLAW_SRC

# 构建 Manager 和 Worker（依赖 openclaw-base）
make build-manager build-worker

# 构建 CoPaw Worker（需要 GitHub 访问下载 CoPaw）
export HTTPS_PROXY=http://127.0.0.1:1083
export HTTP_PROXY=http://127.0.0.1:1083
make build-copaw-worker
```

## 4. 简化方案（推荐）

### 方案 A：混合构建（推荐）

**核心 HiClaw 本地构建** + **基础服务镜像拉取**

```bash
# 1. 拉取基础服务镜像（这些镜像稳定，不需要频繁修改）
docker pull minio/minio:latest
docker pull minio/mc:latest
docker pull vectorim/element-web:latest

# 打标签为 HiClaw 使用的格式
docker tag minio/minio:latest higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/minio:20260216
docker tag minio/mc:latest higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/mc:20260216
docker tag vectorim/element-web:latest higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/element-web:20260216

# 2. 本地构建 HiClaw 核心镜像
cd $HICLAW_SRC
make build-openclaw-base build-manager build-worker

# CoPaw 可选（如果需要）
export HTTPS_PROXY=http://127.0.0.1:1083
make build-copaw-worker
```

### 方案 B：全部本地构建

如果需要完全离线或完全自定义，需要：
1. 本地搭建 Docker Registry
2. 修改所有 Dockerfile 的 FROM 镜像
3. 按依赖顺序逐个构建

## 5. 当前环境状态

### 已准备好的镜像
```
hiclaw/manager-agent:latest       ✅ 已构建
hiclaw/worker-agent:latest        ✅ 已构建
```

### 需要处理的基础镜像
```
higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/all-in-one:sha-d32debd  ⬜ 需拉取或构建
higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/tuwunel:20260216         ⬜ 需查找仓库
higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/minio:20260216           ⬜ 可拉取或构建
higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/mc:20260216              ⬜ 可拉取或构建
higress-registry.cn-hangzhou.cr.aliyuncs.com/higress/element-web:20260216     ⬜ 可拉取或构建
```

### HiClaw 待构建
```
hiclaw/openclaw-base:latest       ⬜ 待构建（需 GitHub 访问）
hiclaw/copaw-worker:latest        ⬜ 待构建（需 GitHub 访问）
```

## 6. 下一步建议

**当前进展：**
- ✅ Colima 环境就绪
- ✅ Manager、Worker 镜像已构建
- ⬜ 基础服务镜像待处理
- ⬜ openclaw-base、CoPaw 待构建（需 GitHub）

**建议操作：**

1. **先尝试使用已构建的镜像安装 HiClaw**
   - 拉取缺失的基础镜像
   - 跳过 CoPaw（可选组件）
   - 验证核心功能

2. **然后逐步完善本地构建**
   - 配置 GitHub 代理
   - 构建 openclaw-base
   - 构建 CoPaw

**或者：**

直接告诉我你想怎么处理这些基础镜像：
- A: 直接拉取（快速开始）
- B: 尝试本地构建 Element Web 和 mc
- C: 先尝试安装，后续再完善本地构建
