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

## 一、结论（PM / 交付用）

| 功能         | 结论            | 说明                                        |
|--------------|-----------------|---------------------------------------------|
| 工单AI回复   | {✅/⚠️/❌} {label} | {one sentence — what works or what's missing} |
| Livechat对接 | {✅/⚠️/❌} {label} | {one sentence}                              |
| 数据同步     | {✅/⚠️/❌} {label} | {one sentence}                              |

Labels: 可行 / 部分可行（需适配）/ 不可行

### 建议

{2–3 sentences: which features to implement, which to skip, any sequencing recommendation}

---

## 二、技术差距分析（研发用）

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

## Standalone vs Orchestrated

- **Standalone** (`/intelli:report`): Generate and save the report, then stop.
- **Orchestrated** (called from `intelli:analyze`): Generate and save the report, then return control to the orchestrator for checkpoint C.
