---
name: analyze
description: Full Intelli platform analysis flow. Orchestrates check-api → map-arch → report with user checkpoints between each phase. Use this for any platform feasibility evaluation. Optionally hands off to superpowers:brainstorming when implementation is desired.
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
If user says continue: invoke `superpowers:brainstorming` with context:
  - Platform name
  - Which features were deemed feasible
  - The path to the saved report file
  - Note: "请参考报告中的接入 checklist 作为实现起点"

---

## Passing Context Between Phases

When invoking sub-skills, pass the relevant output as context:
- Phase 1 → Phase 2: include the full capability matrix text
- Phase 2 → Phase 3: include the full architecture mapping text
- Phase 3 → brainstorming: include platform name, feasible features, report file path

## Error Handling

- If WebFetch fails for a URL: tell the user, ask them to paste the relevant API docs
- If a file path doesn't exist: tell the user the path wasn't found, ask for correct path
- If the platform has no public API docs findable via search: ask the user to provide the docs manually
