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

**角色识别：**
- 若来自 `intelli:analyze`（已有角色上下文）：直接使用，不再询问
- 若直接调用：在收集业务背景后，询问角色：
  ```
  你是哪类受众？
  1. PM / 交付
  2. 产品 / 架构
  3. 研发
  4. Claude（AI 开发）
  ```
  记录角色标识：`pm` / `arch` / `dev` / `claude`

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

## Phase D: 前端集成评估

After Phase C, synthesize authorization and manual configuration findings from
Phase B into a structured Frontend Integration section. Scan all Phase B steps for:

- **授权/凭证类 Step**（平台鉴权、API Key 生成、OAuth 授权）→ AUTH SECTION
- **我方系统配置 Step**（在 Intelli/shulex_gpt 侧的功能开关或参数设置）→ FEATURE SETTINGS SECTION
- **三方后台操作 Step**（需用户在三方平台管理后台手工完成的操作）→ MANUAL GUIDANCE

Output this section in the conversation:

```
前端集成评估 (Frontend Integration)
─────────────────────────────────────────
（从 Phase B 各 Step 汇总授权和手工操作信息）

AUTH SECTION
授权方式: {从授权/凭证类 Step 推导：OAuth 跳转 / API Key 填写 / 子域名+OAuth / 多步骤}
输入字段:
  - {字段名}: {用途} [必填/选填]
  — 无输入字段（OAuth 跳转，无需预填）   ← 纯 OAuth 无子域名时用此行
手工前置步骤（三方平台操作，前端展示引导）:
  ⚠️ {步骤描述}    ← 仅当有手工步骤时；否则写 "— 无手工前置步骤"

FEATURE SETTINGS SECTION
{从"我方系统配置 Step"提取，每个功能点一行}
  - {功能名}: {可配置项说明}
  — 无需额外功能配置    ← 若无我方系统配置 Step

MANUAL GUIDANCE（需在三方平台手工完成，前端展示操作引导）
  ⚠️ Webhook URL 配置: 前端展示 Shulex Webhook URL，提示用户在三方后台填入  ← 仅当涉及 Webhook 时包含
  ⚠️ {其他三方后台操作 Step 的操作说明}
  — 无手工步骤    ← 无 Webhook 且无其他三方后台操作时用此行
```

Pass this Frontend Integration section to `intelli:report` as additional context
alongside the chain-mode flag.

## Report Generation

Phase C 完成后，调用 `intelli:report` skill，传入：
- Phase B 的完整验证结果
- Phase C 的链路可行性总结
- Phase D 的前端集成评估（Frontend Integration section）
- 当前用户角色（`pm` / `arch` / `dev` / `claude`）
- 模式标识：`chain-mode`（让 report skill 使用链路模式模板）

`intelli:report` 将生成四份文档到：
```
docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}/
  pm.md / arch.md / dev.md / spec.md
```

并按角色展示规则输出对话内容（完整展示当前角色文档，其余三份给路径）。

## Standalone vs Orchestrated

- **Standalone** (`/intelli:flow-analyze`): 先收集业务背景，然后执行完整流程。
- **Orchestrated**（来自 `intelli:analyze` 链路模式）: 接收 Phase 1 上下文直接从 Phase A 开始。
