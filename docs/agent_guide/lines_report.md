# HiClaw 代码库语言统计报告

**统计时间**: 2026-03-15

## 总体统计

| 语言 | 文件数 | 代码行数 | 占比 |
|------|--------|----------|------|
| **Markdown** | 65 | 13,968 | 32.9% |
| **Shell** | 57 | 12,503 | 29.5% |
| **JSON** | 3 | 6,835 | 16.1% |
| **Python** | 11 | 3,558 | 8.4% |
| **YAML** | 8 | 2,506 | 5.9% |
| **PowerShell** | 1 | 2,081 | 4.9% |
| **Makefile** | 1 | 485 | 1.1% |
| **Dockerfile** | 4 | 337 | 0.8% |
| **Conf** | 1 | 133 | 0.3% |
| **TOML** | 1 | 25 | 0.1% |
| **总计** | **152** | **42,431** | 100% |

## Markdown 文件详细分布

### 按目录汇总

| 行数 | 文件数 | 目录 |
|------|--------|------|
| 5,837 | 30 | manager/agent/ |
| 2,652 | 8 | docs/zh-cn/ |
| 2,304 | 7 | docs/ |
| 826 | 2 | blog/zh-cn/ |
| 816 | 2 | blog/ |
| 766 | 3 | 根目录 |
| 303 | 7 | changelog/ |
| 185 | 1 | install/ |
| 86 | 1 | tests/ |
| 81 | 1 | manager/ |
| 59 | 1 | worker/ |
| 36 | 1 | docs/agent_guide/ |
| 17 | 1 | copaw/ |

### 主要文档说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `manager/agent/skills/project-management/SKILL.md` | 625 | 项目管理技能文档 |
| `manager/agent/skills/worker-management/SKILL.md` | 483 | Worker 管理技能文档 |
| `manager/agent/copaw-worker-agent/AGENTS.md` | 361 | CoPaw Worker Agent 指南 |
| `docs/zh-cn/windows-deploy.md` | 521 | Windows 部署指南(中文) |
| `docs/windows-deploy.md` | 514 | Windows 部署指南(英文) |
| `blog/zh-cn/hiclaw-announcement.md` | 512 | 开源发布公告(中文) |
| `blog/hiclaw-announcement.md` | 511 | 开源发布公告(英文) |
| `README.zh-CN.md` | 300 | 中文版 README |
| `README.md` | 305 | 英文版 README |
| `AGENTS.md` | 161 | 项目 Agent 指南 |

## Shell 脚本详细分布

### 按目录汇总

| 行数 | 文件数 | 目录 |
|------|--------|------|
| 3,329 | 18 | manager/agent/skills/ |
| 1,983 | 12 | manager/scripts/ |
| 2,054 | 1 | install/ |
| 1,920 | 5 | tests/lib/ |
| 1,851 | 14 | tests/ |
| 415 | 1 | scripts/ |
| 391 | 2 | manager/tests/ |
| 242 | 1 | hack/ |
| 177 | 1 | worker/scripts/ |
| 72 | 1 | docs/agent_guide/ |
| 69 | 1 | copaw/scripts/ |

### 主要脚本说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `install/hiclaw-install.sh` | 2,054 | 一键安装脚本 |
| `manager/agent/skills/worker-management/scripts/create-worker.sh` | 679 | Worker 创建脚本 |
| `tests/lib/agent-metrics.sh` | 1,116 | Agent 指标检测库 |
| `manager/agent/skills/worker-management/scripts/lifecycle-worker.sh` | 378 | Worker 生命周期管理 |
| `manager/agent/skills/worker-management/scripts/push-worker-skills.sh` | 300 | Worker 技能推送 |
| `manager/scripts/init/start-manager-agent.sh` | 455 | Manager Agent 启动脚本 |
| `manager/scripts/lib/container-api.sh` | 565 | 容器 API 操作库 |
| `scripts/replay-task.sh` | 415 | 任务重放脚本 |
| `manager/scripts/init/setup-higress.sh` | 296 | Higress 网关初始化 |
| `hack/mirror-images.sh` | 242 | 镜像同步脚本 |

## Python 文件详细分布

### 按目录汇总

| 行数 | 文件数 | 目录 |
|------|--------|------|
| 2,238 | 7 | `copaw/src/` |
| 1,217 | 3 | `copaw/scripts/` |
| 103 | 1 | `manager/agent/` |

### 主要文件说明

| 文件 | 行数 | 说明 |
|------|------|------|
| `copaw/src/copaw_worker/matrix_channel.py` | 1,083 | Matrix 频道通信模块 |
| `copaw/src/copaw_worker/worker.py` | 398 | CoPaw Worker 核心实现 |
| `copaw/src/copaw_worker/bridge.py` | 308 | 桥接层，连接 AgentScope 和 Matrix |
| `copaw/scripts/patch_reme_lazy.py` | 543 | ReME 库补丁脚本 |
| `copaw/scripts/patch_agentscope_lazy.py` | 489 | AgentScope 延迟加载补丁 |
| `copaw/scripts/patch_agentscope_runtime_lazy.py` | 185 | AgentScope 运行时补丁 |
| `copaw/src/copaw_worker/sync.py` | 352 | 文件同步模块 |
| `copaw/src/copaw_worker/cli.py` | 68 | 命令行接口 |
| `manager/agent/copaw-worker-agent/skills/file-sync/scripts/copaw-sync.py` | 103 | CoPaw 文件同步脚本 |

### 说明

- **CoPaw** 是 AgentScope 的轻量级封装，所有 Python 代码都在 `copaw/` 目录
- `matrix_channel.py` 是最大的单文件，负责 Matrix 协议的底层通信
- `worker.py` 是 CoPaw Worker 的核心逻辑
- `copaw/scripts/` 下的 `patch_*.py` 是运行时补丁，用于解决依赖库的兼容性问题

## 重新统计

运行以下命令重新生成统计：

```bash
cd $HICLAW_SRC
bash docs/agent_guide/count_lines.sh
```

## 说明

- 统计包含空行和注释行
- Shell 脚本主要集中在安装、技能管理和测试框架
- Markdown 文档集中在技能说明、API 文档和用户指南
- Python 代码全部用于 CoPaw Worker（AgentScope 轻量级封装）
- Manager Agent 是代码量最大的模块（~10K 行 Shell + Markdown）
