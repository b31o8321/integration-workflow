# intelli — Shulex Intelli 平台接入分析插件

在 Claude Code 中评估第三方平台能否接入 Shulex Intelli，覆盖四个核心评估维度：工单 AI 回复、Livechat 对接、数据同步、**前端集成评估**。

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

### 入口命令

```
/intelli:analyze <平台名称 / API 文档 URL / 本地文件路径>
```

Phase 1 收集业务背景后，选择分析模式：

**模式一：标准能力评估**
```
Phase 1: 业务场景收集 + 模式选择
Phase 2: API 能力检查    →  四维度能力矩阵（工单/Livechat/数据同步/前端集成）
Phase 3: 架构映射        →  接口差距分析
Phase 4: 偏差评估        →  直接套用 / 简单改造 / 新链路设计
Phase 5: 可行性报告      →  研发 checklist + 工作量评估
```
适合：快速判断平台是否满足 Intelli 标准接入要求（工单/Livechat/数据同步）

**模式二：业务链路验证**
```
Phase 1:    业务场景收集 + 模式选择
Phase A:    AI 推导技术链路  →  用户确认/修正
Phase B:    逐段 API 验证    →  API端点 + 文档链接 + 系统能力对照
Phase C:    链路可行性总结   →  有条件/需开发 附三方资料
Phase D:    前端集成评估     →  Drawer 规格（授权/功能设置/手工操作引导）
报告生成:   链路可行性报告   →  PM总览 + 研发详情 + 实现checklist
```
适合：有明确业务场景，需要知道端到端能否跑通

### 单独执行各阶段

```
/intelli:flow-analyze  — 单独运行业务链路验证
/intelli:check-api     — 仅输出能力矩阵（标准模式快速判断）
/intelli:map-arch      — 仅做架构映射（需已有能力矩阵）
/intelli:report        — 仅生成报告
/intelli:update-kb     — 更新系统能力知识库（需 /add-dir 代码库）
```

## 各角色适用场景

分析开始时 Claude 会询问你的身份，整个对话和最终报告都将按角色定制。

| 角色 | 对话风格 | 专属报告 |
|------|---------|---------|
| PM / 交付 | 业务语言，不展示 API 细节，聚焦结论与工作量 | `pm.md`：结论、建议、工作量汇总、主要风险 |
| 产品 / 架构 | 适量技术深度，强调系统边界与架构决策 | `arch.md`：数据流、架构决策、前置条件 |
| 研发 | 完整技术细节，主动展示 API 端点与差距 | `dev.md`：差距分析、工作量明细、接入 Checklist |
| Claude（AI 开发） | 结构化输出，为 writing-plans 优化 | `spec.md`：需求规格、验收标准、依赖 |

四份报告**总是全部生成**，对话中仅完整展示当前角色对应的那份，其余给文件路径。

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

每次分析生成四份文档，保存至子目录：

```
docs/platform-analysis/YYYY-MM-DD-{platform-name}/
  pm.md      # PM / 交付版
  arch.md    # 产品 / 架构版
  dev.md     # 研发版
  spec.md    # Claude Spec（writing-plans 输入）
```

## Skills 列表

| Skill | 说明 |
|-------|------|
| `intelli:analyze` | 平台分析入口（标准模式 + 链路模式） |
| `intelli:flow-analyze` | 业务链路验证（Phase A/B/C + 链路报告） |
| `intelli:check-api` | API 能力矩阵分析（工单/Livechat/数据同步/前端集成四维度） |
| `intelli:map-arch` | 映射到 Intelli 接口规范（含 ChannelAuth 凭证模式判断） |
| `intelli:report` | 生成角色定制的四份报告文档（pm/arch/dev/spec）；spec.md 含 E2E 验收 Checklist |
| `intelli:update-kb` | 分析代码库，更新系统能力知识库 |

## 集成验收要求

> spec.md 中的验收标准分两个层次，**两层都通过才算交付**：

| 层次 | 内容 | 时机 |
|------|------|------|
| 单元测试 | `XxxTicketPluginTest`（无凭证，测纯逻辑） | CI 自动执行，代码合并前 |
| API 连通性 | `XxxClientTest`（去掉 `@Ignore`，填真实凭证） | 手动执行，代码合并前 |
| E2E 端对端 | 完整链路：三方事件 → Intelli → AI 回复出现在三方 UI | staging 环境手动执行，上线前 |

## 版本管理（维护者必读）

修改任何 `SKILL.md` 或 `knowledge-base/` 文件后，**必须** bump `package.json` 版本号：

| 变更类型 | 版本号 |
|---------|--------|
| 知识库更新、措辞修正 | x.x.N（patch） |
| 新增功能、流程调整 | x.N.0（minor） |
| 架构重构 | N.0.0（major） |

版本号不 bump 则 `/reload-plugins` 不会重新拉取，用户拿到的仍是旧版本。
