---
name: report
description: Generates a two-tier feasibility report from the architecture mapping (intelli:map-arch). Tier 1 is a traffic-light summary for PM/Delivery. Tier 2 is a detailed gap analysis and integration checklist for developers. Saves to docs/platform-analysis/.
---

# intelli:report — Feasibility Report Generator

## Purpose

Generate a structured feasibility report in two tiers from the architecture mapping.
Save it as a markdown file for sharing with PM, delivery, and dev teams.

This is Phase 3 of the full analysis flow. Can also be used standalone if you
already have the architecture mapping output.

## Input

Either:
- The architecture mapping from `intelli:map-arch` (if called from `intelli:analyze`)
- A user-provided summary of platform capabilities and gaps (if used standalone)

## Report Structure

Generate the following report, filling in all sections with real analysis:

```markdown
# {Platform Name} 接入可行性评估

> 分析日期: {YYYY-MM-DD}
> 分析人: Claude (intelli:analyze)
> 数据来源: {URL / file / description}

---

## ⚠️ 授权前置条件
{Only include this block if authorization model is MARKETPLACE_APP or CONDITIONAL. If SELF_AUTH, omit entirely.}

> 🚨 **本平台需通过官方 Marketplace App 审核才能对客户进行授权。**
>
> - **申请流程**: {描述申请步骤}
> - **预计审核周期**: {X 周 / 不确定}
> - **受限能力**: {审核前无法访问的 API 列表}
> - **建议**: 在启动研发前，先行提交申请，避免研发完成后因审核延误上线。

---

## 一、结论（PM / 交付用）

| 功能         | 结论            | 说明                                        |
|--------------|-----------------|---------------------------------------------|
| 授权模式     | {✅ 客户自助授权 / 🚨 需申请审核 / ⚠️ 部分受限} | {one sentence} |
| 工单AI回复   | {✅/⚠️/❌} {label} | {one sentence — what works or what's missing} |
| Livechat对接 | {✅/⚠️/❌} {label} | {one sentence}                              |
| 数据同步     | {✅/⚠️/❌} {label} | {one sentence}                              |

Labels: 可行 / 部分可行（需适配）/ 不可行

### 建议

{2–3 sentences: which features to implement, which to skip, any sequencing recommendation}

---

## 二、技术差距分析（研发用）

### 授权与接入模式

**授权类型：** {API Key / OAuth2 / JWT / Basic Auth}
**授权模式：** {✅ 客户自助授权 / 🚨 需 Marketplace App 审核 / ⚠️ 部分受限}

{If MARKETPLACE_APP or CONDITIONAL:}
**申请要求：**
- 申请入口: {URL}
- 申请材料: {描述}
- 审核周期: {预估}
- 受限 API: {列表}
- **风险提示**: 建议将申请列为 P0 前置任务，优先于研发启动。

---

### 工单AI回复

**可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

**差距列表：**
{For each ⚠️ or ❌ gap found in map-arch:}
- [{Minor/Medium/Blocking}] {gap description} → {recommended workaround or "no workaround"}

**预估工作量：** {小（3–5天）/ 中（1–2周）/ 大（2–4周）/ 不建议实现}

---

### Livechat对接

**可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

**差距列表：**
{same format}

**预估工作量：** {same format}

---

### 数据同步

**可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

**差距列表：**
{same format}

**预估工作量：** {same format}

---

## 三、接入 Checklist（研发用）

> 仅列出可行或部分可行的功能。不可行功能不生成 checklist。

### 工单AI回复接入 Checklist
{Only include this section if Ticket AI Reply is ✅ or ⚠️}

- [ ] `ExternKeySourceEnum` 中注册新平台枚举
- [ ] 创建 Maven 子模块 `intelli-ticket-{platform}`
- [ ] 实现 `TicketPlatformPlugin`
  - [ ] `platformId()` 与 ExternKeySourceEnum 一致
  - [ ] `extractCredentialKey()` 从 URL token 提取
  - [ ] `parseWebhook()` 解析 webhook payload + 签名验证
  - [ ] `createOperations()` 创建 ExternKey
  - [ ] `parsePlatformConfig()` 解析平台特有配置
- [ ] 实现 `TicketOperations`
  - [ ] `getMessages()` — 接口: {platform API endpoint}
  - [ ] `getTags()` — 接口: {platform API endpoint}
  - [ ] `getSubject()` — 接口: {field in ticket response}
  - [ ] `sendReply()` — 接口: {platform API endpoint}
  - [ ] `applyTags()` — 接口: {platform API endpoint} {note any workaround}
  - [ ] `lockKey()` 包含 tenantId + 工单ID
- [ ] 创建 `AutoConfiguration` 并注册
- [ ] 配置 `intelli.ticket.v2.enabled=true`
- [ ] 配置 webhook URL: `/v2/webhook/{PLATFORM_ID}/{token}`

### Livechat接入 Checklist
{Only include this section if Livechat is ✅ or ⚠️}

- [ ] 实现 Livechat 消息接收通道（{WebSocket / Webhook / Polling}）
- [ ] 实现 outbound 消息发送 — 接口: {endpoint}
- [ ] 实现 session 生命周期处理（{note workarounds if needed}）
- [ ] 消息幂等 key: {field name}
- [ ] 接入 Kafka 消息管道

### 数据同步接入 Checklist
{Only include this section if Data Sync is ✅ or ⚠️, and only for feasible sub-features}

- [ ] 实现 `ISyncService` 订单同步（{if order sync feasible}）
  - [ ] 增量拉取参数: {param name}
  - [ ] 分页实现: {cursor / page+size}
- [ ] 实现 `ISyncService` 商品同步（{if product sync feasible}）
- [ ] 实现物流数据同步（{if logistics feasible}）
- [ ] Rate limit 处理: {strategy}
```

## Save Location

Create the output directory if it doesn't exist, then save:

```
docs/platform-analysis/YYYY-MM-DD-{platform-name-lowercase-hyphenated}.md
```

Example: `docs/platform-analysis/2026-04-03-freshdesk.md`

Announce the save path after writing: "报告已保存至 `docs/platform-analysis/...`"

## Chain Mode Report (链路模式报告)

当被 `intelli:flow-analyze` 调用时，生成链路模式报告而非三维度报告。

链路模式报告保存至：`docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}.md`

报告包含三个部分：

**一、链路总览（PM / 交付用）**
- {If MARKETPLACE_APP:} 🚨 **授权前置条件**：需完成 Marketplace App 申请审核
- Step 汇总表：Step 编号 / 描述 / 平台 / 结论 / 关键说明
- 整体结论（可行 / 部分可行 / 存在阻断）
- 主要前置条件列表
- 研发主要工作列表

**二、逐段详细分析（研发用）**
- 每个 Step 的完整验证结果
- API / 配置表格，每行附文档链接
- 我方能力对照（来自 knowledge-base）
- ⚠️ 有条件：附确认方式 + 参考资料链接
- ⚠️ 需开发：附工作量估算 + 研发参考资料链接
- ❌ 阻断：附技术限制说明和文档证据

**三、实现 Checklist（研发用）**
- 仅列出可行、有条件、需开发的 Step
- 每 Step 生成可执行的研发 checklist 条目

## Standalone vs Orchestrated

- **Standalone** (`/intelli:report`): Generate and save the report, then stop.
- **Orchestrated** (called from `intelli:analyze`): Generate and save the report, then return control to the orchestrator for checkpoint C.
