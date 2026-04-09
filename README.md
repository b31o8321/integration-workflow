# intelli — Shulex Intelli 平台接入分析插件

在 Claude Code 中评估第三方平台能否接入 Shulex Intelli，覆盖三个核心功能维度：工单 AI 回复、Livechat 对接、数据同步。

## 安装

### 方式一：Claude Code 插件市场安装（推荐）

在 Claude Code 输入框中执行：

```
/plugin marketplace add b31o8321/integration-workflow
/plugin install intelli@intelli
/reload-plugins
```

### 方式二：本地安装

```bash
git clone https://github.com/b31o8321/integration-workflow
cd integration-workflow
./install.sh
```

`install.sh` 会将 skills 软链到 `~/.claude/skills/intelli/`，重启 Claude Code 后生效。

## 使用方式

### 完整分析流程（推荐）

```
/intelli:analyze <平台名称 / API 文档 URL / 本地文件路径 / 粘贴的 API 描述>
```

分阶段依次执行，每阶段结束后可以选择停止：

```
Phase 1: 业务场景收集    →  明确目标功能方向
Phase 2: API 能力检查    →  能力矩阵
Phase 3: 架构映射        →  接口差距分析
Phase 4: 偏差评估        →  直接套用 / 简单改造 / 新链路设计
Phase 5: 可行性报告      →  研发 checklist + 工作量评估
```

### 单独执行各阶段

```
/intelli:check-api   — 仅输出能力矩阵（适合快速判断）
/intelli:map-arch    — 仅做架构映射（需已有能力矩阵）
/intelli:report      — 仅生成报告（需已有架构映射）
```

## 各角色适用场景

| 角色 | 推荐用法 | 获得产出 |
|------|---------|---------|
| PM / 交付 | `/intelli:analyze` 在 Phase 2 停止 | 能力矩阵，快速判断可行性 |
| 技术负责人 | `/intelli:analyze` 在 Phase 4 停止 | 差距分析 + 偏差评估（改造量） |
| 研发团队 | `/intelli:analyze` 完整执行 | Markdown 报告 + 接入 checklist |

## 输入格式

`check-api` 支持以下任意输入形式：

- 平台名称（如 `Freshdesk`）— 自动搜索官方 API 文档
- API 文档 URL — 直接抓取解析
- 本地文件路径 — 支持 `.md` / `.pdf` / `.json` / OpenAPI spec
- 直接粘贴 API 描述文本

## API 真实性验证（可选）

`check-api` 完成后可提供凭证进行真实调用验证：

- **读操作**：自动执行，结果即时展示；有必填参数时会先询问
- **写操作**：生成 curl 命令，由用户手动执行，不自动调用
- **Webhook / WebSocket**：摘录官方文档，人工确认

## 报告输出位置

报告保存至当前工作目录：

```
docs/platform-analysis/YYYY-MM-DD-{platform-name}.md
```

## Skills 列表

| Skill | 说明 |
|-------|------|
| `intelli:analyze` | 完整三阶段分析编排器 |
| `intelli:check-api` | API 能力矩阵分析 |
| `intelli:map-arch` | 映射到 Intelli 接口规范 |
| `intelli:report` | 生成双层可行性报告 |
