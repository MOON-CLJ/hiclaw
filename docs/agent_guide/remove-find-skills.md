# 移除 find-skills 功能

## 背景

`find-skills` 是 Worker 的自助技能发现和安装功能。启用后，Worker 遇到不会的任务时会自动去 [skills.sh](https://skills.sh)（或指定的私有注册中心）搜索并安装第三方技能包。

### 安全风险

Worker 可以**自主从外部下载并执行任意代码**，admin 无法事先审核。这违反了 HiClaw 的核心设计原则——Worker 的技能由 Manager 统一管理，admin 对 Worker 的能力边界有完全控制权。

### 决定

彻底移除 `find-skills` 功能。Worker 的技能完全由 admin 通过 Manager 手动指定和推送。

---

## 原有工作流程（已移除）

```
Admin 创建 Worker 时选择启用 find-skills
    ↓
create-worker.sh --find-skills [--skills-api-url URL]
    ↓
find-skills/SKILL.md 被推送到 Worker 的 MinIO 空间
    ↓
Worker 容器启动，拉取 SKILL.md，skills CLI 可用
    ↓
Worker 遇到未知任务 → 执行 skills find <query> → skills add <package> -g -y
    ↓
第三方技能代码被下载并执行，自动同步回 MinIO 持久化
```

---

## 改动范围

### 镜像层（重新构建后生效）

| 文件 | 改动 |
|------|------|
| `openclaw-base/Dockerfile` | 删除 `npm install -g skills`，镜像中不再预装 skills CLI |
| `worker/scripts/worker-entrypoint.sh` | 移除 `~/.agents/skills` symlink 和 `skills-lock.json` 恢复逻辑 |

### 脚本层

| 文件 | 改动 |
|------|------|
| `manager/agent/skills/worker-management/scripts/create-worker.sh` | 移除 `--find-skills`、`--skills-api-url` 参数解析及 `ENABLE_FIND_SKILLS` 相关逻辑 |
| `install/hiclaw-install.sh` | 移除 `install_worker()` 中 `--find-skills`、`--skills-api-url` 参数及 `SKILLS_API_URL` 环境变量注入 |

### Skill 源文件

| 文件 | 改动 |
|------|------|
| `manager/agent/worker-skills/find-skills/SKILL.md` | 整文件删除（166 行） |
| `manager/agent/worker-skills/README.md` | 移除 find-skills 相关说明 |

### Agent 配置（Manager 端）

| 文件 | 改动 |
|------|------|
| `manager/agent/TOOLS.md` | 推荐表格移除 `--find-skills` 标记 |
| `manager/agent/skills/task-management/SKILL.md` | 移除 Step 4（Find-Skills）和相关引用 |
| `manager/agent/skills/worker-management/SKILL.md` | 移除 `--find-skills` 参数文档、`enable_find_skills` 配置项 |

### Agent 配置（Worker 端）

| 文件 | 改动 |
|------|------|
| `manager/agent/worker-agent/TOOLS.md` | 移除 find-skills 使用指南（搜索、安装、优先规则） |

---

## 未改动（合理保留）

| 文件 | 位置 | 原因 |
|------|------|------|
| `install/hiclaw-install.sh` | `HICLAW_SKILLS_API_URL` 写入 env 文件 | 仅作为可选配置字段存入文件，不触发任何功能 |
| `manager/scripts/lib/container-api.sh` | 注释中 `SKILLS_API_URL` 示例 | 仅为参数格式举例，不涉及 find-skills 逻辑 |

---

## 生效方式

1. **策略层**：Agent 配置修改在下次 Manager/Worker 容器启动或 skill 推送时自动生效
2. **镜像层**：需要重新构建 openclaw-base 和 worker 镜像：
   ```bash
   make build-openclaw-base
   make build-worker OPENCLAW_BASE_IMAGE=hiclaw/openclaw-base OPENCLAW_BASE_VERSION=latest
   ```
3. **已有 Worker**：如果已创建的 Worker 带有 find-skills 技能，可通过 Manager 在 Element Web 中发消息要求移除（Manager 会从 workers-registry.json 和 MinIO 中清理）
