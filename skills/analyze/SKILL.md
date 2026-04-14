---
name: analyze
description: Full Intelli platform analysis flow. Phase 1 collects business context and offers two modes: (1) standard three-dimension capability matrix, or (2) business flow validation with API-level detail and doc links. Use this as the single entry point for all platform evaluations.
version: 1.1.0
---

# intelli:analyze — Platform Analysis Orchestrator

## Purpose

Run the full platform analysis flow with a single upfront scope choice.
Produces a spec.md ready for `superpowers:writing-plans`.

## Trigger

Use this skill whenever the user wants to evaluate whether a platform can be integrated
into Shulex Intelli. Input can be a platform name, URL, file path, or pasted API content.

## Flow

### Phase 1: 业务场景收集

**角色默认为 `claude`**（生成 spec.md 供 writing-plans 使用，结构化输出）。
若用户明确提到 "PM 视角" / "架构评审" / "研发视角"，则切换对应角色；否则不询问。

**在任何技术分析开始之前**，询问业务背景（仅在用户未说明时）：

```
在开始分析之前，请简要描述：

1. 业务场景是什么？（例如：客服工单处理、实时在线客服、售后数据同步等）
2. 希望实现什么效果？（例如：AI 自动回复工单、同步订单数据到 Intelli）
3. 最关注哪个功能方向？（工单 AI 回复 / Livechat 对接 / 数据同步，或全部）
```

若用户已在触发命令中说明功能方向（如 "分析一下 Freshdesk，要做工单 AI 回复"），直接跳过此问。

**然后询问分析深度（仅一次）**：

```
你需要完整分析还是快速判断？

→ A. 完整分析（推荐）: 能力矩阵 → 架构映射 → 偏差评估 → 报告 → 进入实现
→ B. 快速判断: 仅能力矩阵（适合 PM / 快速评估可行性）
→ C. 业务链路验证: 逐段验证端到端链路（适合有明确业务场景的深度分析）
```

- 选 A（默认）：执行 Phase 2–5 完整流程，Phase 2/3/4 之间**不再询问**，直接推进
- 选 B：仅执行 Phase 2，完成后停止
- 选 C：调用 `intelli:flow-analyze` skill，传入业务背景和平台信息

---

### Setup

Before starting, confirm what the user wants to analyze if not clear:
- If a URL, file path, or substantial text was provided: proceed directly
- If only a platform name was given: acknowledge and proceed — use WebSearch/WebFetch to find their public API docs

Announce: "开始分析 {Platform Name}（完整分析模式）。"

---

### Phase 2: API Capability Check

Invoke the `intelli:check-api` skill with the platform information.

**若选 B**：分析完成后停止，向用户展示能力矩阵。
**若选 A**：分析完成后**直接进入 Phase 3，不询问**。

---

### Phase 3: Architecture Mapping

Invoke the `intelli:map-arch` skill with the capability matrix from Phase 2.

完成后**直接进入 Phase 4，不询问**。

---

### Phase 4: 偏差评估（与现有 shulex_intelli 项目）

Based on the feasibility verdict from Phase 3, assess how much the integration deviates from existing shulex_intelli capabilities. Evaluate under **each feasible feature dimension**:

| 评估结论 | 判断依据 |
|----------|---------|
| **直接套用** | 平台 API 完全匹配现有 SPI 接口规范，无需改动现有代码，只需新增 adapter 实现 |
| **简单改造** | 现有链路可复用，但需少量修改（< 5 天）：如新增字段映射、兼容不同 webhook 格式、增加轮询 fallback |
| **新链路设计** | 现有架构无法满足，需要设计新的处理链路（> 5 天）：如全新的事件模型、不兼容的认证机制、完全不同的数据流 |

Output the assessment in this format:

```
偏差评估: {Platform Name}
═══════════════════════════════════════════════════════════════

工单 AI 回复:  {直接套用 / 简单改造 / 新链路设计}
  → {具体说明：哪些地方需要改造，或哪些链路需要重新设计}

Livechat 对接: {直接套用 / 简单改造 / 新链路设计}
  → {说明}

数据同步:      {直接套用 / 简单改造 / 新链路设计}
  → {说明}
```

完成后**直接进入 Phase 5，不询问**。

---

### Phase 5: Report Generation

Invoke the `intelli:report` skill with:
- The architecture mapping from Phase 3
- The deviation assessment from Phase 4
- The role identifier (default: `claude`; pass as context: "当前用户角色: claude")

After the report is saved, announce the file path.

**CHECKPOINT（仅此一次）— ask the user:**

```
可行性报告已生成。

是否进入实现阶段？

→ 继续：启动 superpowers:brainstorming 开始设计
→ 停止：分析完成，报告已保存至 {path}
```

If user says stop: end with a one-paragraph summary of findings.
If user says continue:

  **First, verify codebases are in context:**

  需要以下代码库已通过 `/add-dir` 加入当前会话：
  - `shulex-intelli`（后端实现）
  - `shulex-smart-service`（前端实现，如需前端集成）

  若未添加：

  ```
  在启动实现阶段之前，请先添加代码库：

  /add-dir /path/to/shulex-intelli
  /add-dir /path/to/shulex-smart-service   ← 如需前端集成

  添加后告知我，将继续启动设计阶段。
  ```

  Wait for user to confirm before proceeding.

  Once codebases are confirmed available, invoke `superpowers:brainstorming` with the following context block (pass verbatim):

  ```
  平台: {Platform Name}
  业务场景: {business scenario from Phase 1}
  可行功能: {list of ✅/⚠️ features from Phase 3}
  偏差评估: {deviation assessment from Phase 4}
  报告文件: {report file path}

  架构背景（shulex-intelli 关键约定）:
  - 新平台接入使用 ChannelAuth 模式（channel_auth 表 + ChannelTypeEnum），不使用 ExternKey
  - 覆盖 resolveCredential() 和 resolveCredentialByKey()，参考 LineTicketPlugin
  - Webhook 入口: POST /v2/webhook/{PLATFORM_ID}/{xToken}（WebhookDispatchController 已实现，无需改动）
  - Plugin 通过 Spring AutoConfiguration 自动注册，参考 intelli-ticket-line 模块
  - 前端集成参考 ShopifyAuth（AuthPageScaffold 模式）和 FreshDesk（API Key 授权）

  请参考报告中的接入 checklist 作为实现起点。
  实现完成并执行 superpowers:finishing-a-development-branch 之后，主动运行 /intelli:retrospective 进行复盘。
  ```

---

## Post-Implementation: Retrospective

**每次集成项目分支完成（`superpowers:finishing-a-development-branch` 执行完毕）后，主动调用 `intelli:retrospective` 进行复盘。**

无需等待用户提示。复盘应在以下任意时刻发生：
- `finishing-a-development-branch` 完成后（Option 1 merge / Option 2 PR created / Option 4 discard）
- 用户确认开发工作结束时

传入 context：
- 平台名称
- 实现的功能列表
- 开发过程中纠正的偏差（若有）

---

## Passing Context Between Phases

When invoking sub-skills, pass the relevant output as context:
- Phase 1 → all phases: carry business scenario and target outcome throughout
- Phase 2 → Phase 3: include the full capability matrix text
- Phase 3 → Phase 4: include the feasibility verdict from architecture mapping
- Phase 4 → Phase 5: include the deviation assessment text
- Phase 5 → brainstorming: use the context block template above

## Error Handling

- If WebFetch fails for a URL: tell the user, ask them to paste the relevant API docs
- If a file path doesn't exist: tell the user the path wasn't found, ask for correct path
- If the platform has no public API docs findable via search: ask the user to provide the docs manually

