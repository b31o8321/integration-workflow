---
name: analyze
description: Full Intelli platform analysis flow. Orchestrates check-api → map-arch → report with user checkpoints between each phase. Use this for any platform feasibility evaluation. Optionally hands off to superpowers:brainstorming when implementation is desired.
version: 1.0.0
---

# intelli:analyze — Platform Analysis Orchestrator

## Purpose

Run the full three-phase platform analysis flow with checkpoints between each phase.
The user can stop at any checkpoint — useful for PM quick checks, tech evaluations,
or full dev kickoffs.

## Trigger

Use this skill whenever the user wants to evaluate whether a platform can be integrated
into Shulex Intelli. Input can be a platform name, URL, file path, or pasted API content.

## Flow

### Phase 0: 业务场景收集

**在任何技术分析开始之前**，先了解业务背景：

```
在开始分析之前，请简要描述：

1. 业务场景是什么？（例如：客服工单处理、实时在线客服、售后数据同步等）
2. 希望通过这个对接实现什么效果？（例如：AI 自动回复工单、同步订单数据到 Intelli）
3. 最关注哪个功能方向？（工单 AI 回复 / Livechat 对接 / 数据同步，或全部）
```

Record the answers. This context will:
- Focus Phase 1 analysis on the relevant feature dimensions
- Inform the feasibility and deviation assessment in Phases 2 and 2.5

---

### Setup

Before starting, confirm what the user wants to analyze if not clear:
- If a URL, file path, or substantial text was provided: proceed directly
- If only a platform name was given (e.g. "分析一下 Freshdesk"): acknowledge and proceed —
  use WebSearch/WebFetch to find their public API docs

Announce: "开始分析 {Platform Name}，分为三个阶段，每个阶段结束后可以选择停止。"

---

### Phase 1: API Capability Check

Invoke the `intelli:check-api` skill with the platform information.

After the capability matrix is displayed:

**CHECKPOINT A — ask the user:**

```
能力矩阵分析完成。

是否继续进行架构映射分析？（将平台能力映射到 Intelli 的接口规范）

→ 继续：进入第二阶段
→ 停止：到此为止（适合产品/交付快速判断）
```

If user says stop: thank them and end. The matrix is already displayed.
If user says continue: proceed to Phase 2.

---

### Phase 2: Architecture Mapping

Invoke the `intelli:map-arch` skill with the capability matrix from Phase 1.

After the architecture mapping is displayed:

**CHECKPOINT B — ask the user:**

```
架构映射完成。

是否继续生成完整可行性报告？（包含研发 checklist 和工作量评估）

→ 继续：生成报告
→ 停止：到此为止
```

If user says stop: end.
If user says continue: proceed to Phase 2.5.

---

### Phase 2.5: 偏差评估（与现有 shulex_intelli 项目）

Based on the feasibility verdict from Phase 2, assess how much the integration deviates from existing shulex_intelli capabilities. Evaluate under **each feasible feature dimension**:

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

**CHECKPOINT B.5 — ask the user:**

```
偏差评估完成。

是否继续生成完整可行性报告？（包含研发 checklist 和工作量评估）

→ 继续：生成报告
→ 停止：到此为止
```

If user says stop: end.
If user says continue: proceed to Phase 3.

---

### Phase 3: Report Generation

Invoke the `intelli:report` skill with the architecture mapping from Phase 2.

After the report is saved, announce the file path.

**CHECKPOINT C — ask the user:**

```
可行性报告已生成。

是否进入实现阶段？（将调用 superpowers:brainstorming 开始设计）

→ 继续：启动 superpowers:brainstorming
→ 停止：分析完成，报告已保存
```

If user says stop: end with a summary of findings.
If user says continue:

  **First, verify shulex_intelli project is in context:**

  Check whether the shulex_intelli codebase has been added to the current session.
  If it has NOT been added:

  ```
  在启动实现阶段之前，需要先将 shulex_intelli 项目加入上下文。

  请执行：/add-dir <shulex_intelli 项目路径>

  添加后告知我，将继续启动 superpowers:brainstorming。
  ```

  Wait for user to confirm before proceeding.

  Once shulex_intelli is confirmed available, invoke `superpowers:brainstorming` with context:
  - Platform name
  - Business scenario and desired outcome (from Phase 0)
  - Which features were deemed feasible
  - Deviation assessment per feature (直接套用 / 简单改造 / 新链路设计, from Phase 2.5)
  - The path to the saved report file
  - Note: "请参考报告中的接入 checklist 作为实现起点"

---

## Passing Context Between Phases

When invoking sub-skills, pass the relevant output as context:
- Phase 0 → all phases: carry business scenario and target outcome throughout
- Phase 1 → Phase 2: include the full capability matrix text
- Phase 2 → Phase 2.5: include the feasibility verdict from architecture mapping
- Phase 2.5 → Phase 3: include the deviation assessment text
- Phase 3 → brainstorming: include platform name, business scenario, feasible features, deviation assessment, report file path

## Error Handling

- If WebFetch fails for a URL: tell the user, ask them to paste the relevant API docs
- If a file path doesn't exist: tell the user the path wasn't found, ask for correct path
- If the platform has no public API docs findable via search: ask the user to provide the docs manually
