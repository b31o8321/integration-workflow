---
name: flow-analyze
description: Business flow validation for Intelli integration. Given a business goal and platform list, proposes a technical chain, gets user confirmation, then validates each step at API level with documentation links and knowledge-base capability checks.
version: 1.0.0
---

# intelli:flow-analyze — 业务链路验证

## Purpose

从业务目标出发，推导技术实现链路，并逐段验证每个步骤的 API 可行性。
适合有明确业务场景、需要知道端到端能否跑通的评估场景。

## Input

来自 `intelli:analyze` 的 Phase 1 上下文，或用户直接调用时收集：
- 业务目标描述
- 涉及的平台列表
- 关键约束或已知条件

若直接调用（`/intelli:flow-analyze`），先收集以上信息。

## Phase A: 技术链路推导

基于业务目标和平台列表，将实现路径拆解为有序的 Step 序列。

每个 Step 的格式：

```
Step N: {步骤名称}
  平台/系统: {Zoom CC / GHL / Zenoti / Intelli / shulex_gpt / 其他}
  动作: {具体操作描述}
  依赖: {前置条件或依赖项，若无则填"无"}
```

输出完整链路后，询问用户：

```
以上是根据业务目标推导的技术链路，是否符合你的预期？

→ 确认：进入逐段 API 验证
→ 修正：请说明哪些 Step 需要调整（可新增、删除或修改）
```

等待用户确认或修正。若用户修正，更新链路后再次确认，直到用户确认为止。

## Phase B: 逐段 API 验证

对已确认链路中的每个 Step，依次执行以下分析：

### Step 分析流程

**1. 确定操作类型**

根据 Step 的平台/系统判断：
- 三方平台 API 调用 → 使用 WebFetch 查找具体端点和文档
- 三方后台配置 → 查找配置入口和操作文档
- 我方系统能力（Intelli / shulex_gpt）→ 读取 `knowledge-base/` 对应文件判断现有能力

**2. 文档链接收集规则**

- 使用 WebFetch 抓取官方 API 文档，找到最具体的端点或配置页面 URL
- 每个 API 端点 / 配置操作必须附对应文档 URL
- 若 WebFetch 失败：标注"文档链接待确认 — {官方文档首页 URL}"
- 不得使用训练数据中的 URL，必须通过 WebFetch 实际验证 URL 可访问

**3. 可行性判断标准**

| 结论 | 条件 |
|------|------|
| ✅ 可行 | API 有明确文档 + 我方能力具备 |
| ⚠️ 有条件 | 需三方账户特定配置/权限，或存在已知限制，但技术上可实现 |
| ⚠️ 需开发 | 三方 API 支持，但我方对应能力在 knowledge-base 中标注为 ❌ |
| 🚨 需申请审核 | 三方 API 存在，但需向平台官方申请 Marketplace App / Partner 资质才能使用 |
| ❌ 阻断 | 三方 API 明确不存在，或有根本性技术限制无法绕过 |

**凡遇到 Marketplace App / Partner 申请要求，务必：**
1. 在 Step 结论中标注 🚨 需申请审核
2. 在"有条件说明"中写明申请入口、材料要求、预计审核周期
3. 在 Phase C 总结的"主要前置条件"中置顶列出

**4. 每 Step 输出格式**

```
Step N 验证: {步骤名称}
─────────────────────────────────────────────────
结论: {✅/⚠️/❌} {可行 / 有条件 / 需开发 / 阻断}

API / 配置:
| 操作 | 类型 | 端点 / 入口 | 文档链接 |
|------|------|------------|---------|
| {操作描述} | {API / 后台配置} | {具体端点或路径} | [{页面标题}]({URL}) |

我方能力（knowledge-base）:
| 能力 | 状态 | 备注 |
|------|------|------|
| {能力名称} | ✅/⚠️/❌ | {备注} |

{仅当结论为 ⚠️ 有条件时输出:}
有条件说明: {具体限制描述}
确认方式: {用户或研发如何确认此条件是否满足}
参考资料:
- [{资料名称}]({URL})

{仅当结论为 ⚠️ 需开发时输出:}
需开发说明: {需新建或扩展的模块，预计工作量}
参考资料（供研发）:
- [{资料名称}]({URL})

{仅当结论为 ❌ 阻断时输出:}
阻断原因: {具体说明技术限制，引用文档证据}
```

逐步输出每个 Step 的验证结果，完成所有 Step 后进入 Phase C。

## Phase C: 链路可行性总结

```
链路可行性总览: {业务目标名称}
═══════════════════════════════════════════════════════════════

| Step | 描述 | 平台/系统 | 结论 | 关键说明 |
|------|------|----------|------|---------|
| 1 | {描述} | {平台} | ✅/⚠️/❌ | {一句话说明} |
...

整体结论:
- 完全可行的 Step: N 个
- 有条件可行的 Step: N 个（Step {编号列表}）
- 需开发的 Step: N 个（Step {编号列表}）
- 需申请审核的 Step: N 个（Step {编号列表}）— 🚨 方案实施前置条件
- 阻断的 Step: N 个（Step {编号列表}）

关键阻断点: {若无则写"无硬性阻断"}

主要前置条件:
{🚨 需申请审核的条目置顶，其余按 Step 顺序列出}

研发主要工作:
{列出所有"需开发"Step 的开发任务，每条一行}
```

## Report Generation

Phase C 完成后，生成 Markdown 报告：

**保存路径：** `docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}.md`

**报告结构：**

```markdown
# {业务目标} 链路可行性报告

> 分析日期: YYYY-MM-DD
> 分析人: Claude (intelli:flow-analyze)
> 涉及平台: {平台列表}

---

## 一、链路总览（PM / 交付用）

| Step | 描述 | 平台/系统 | 结论 | 说明 |
|------|------|----------|------|------|
...

**整体结论:** {可行 / 部分可行（N个前置条件，N项待开发）/ 存在阻断}

**主要前置条件:**
{列表}

**研发主要工作:**
{列表}

---

## 二、逐段详细分析（研发用）

{每个 Step 的完整验证输出，含 API 表格、文档链接、参考资料}

---

## 三、实现 Checklist

{仅列出 ✅ 可行、⚠️ 有条件、⚠️ 需开发的 Step}
{每 Step 生成可执行的研发 checklist}
```

报告保存后告知用户路径。

## Standalone vs Orchestrated

- **Standalone** (`/intelli:flow-analyze`): 先收集业务背景，然后执行完整流程。
- **Orchestrated**（来自 `intelli:analyze` 链路模式）: 接收 Phase 1 上下文直接从 Phase A 开始。
