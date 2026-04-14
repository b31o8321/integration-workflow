# Design: check-api Ticket v2 Alignment + Frontend Evaluation Dimension

Date: 2026-04-14
Status: Approved

## Overview

Two changes to the Intelli platform analysis skill suite:

1. **Ticket AI Reply table**: update capability rows to align with the Ticket v2 SPI
   (`TicketPlatformPlugin` + `TicketOperations` interfaces in `shulex-intelli-ticket`)
2. **Frontend Integration dimension**: add a 4th analysis dimension to `check-api`,
   a matching aggregation section to `flow-analyze`, and role-scaled frontend sections
   to `intelli:report`

## Change 1: check-api — 工单 AI 回复 Table

### What changes

| Change | Before | After |
|--------|--------|-------|
| "Webhook push" row | Generic event subscription | Renamed "Webhook push — custom URL"; look-for updated to "platform allows configuring a custom webhook URL" |
| New row | — | "Fetch ticket subject" — Required — `getSubject` — subject/title field in ticket detail API |
| New column | — | `SPI Method` column linking each row to the Ticket v2 interface method |
| Signature row | Unchanged | Maps to `parseWebhook` (signature verification happens inside) |

### Updated table

```
| Capability                       | Required?   | SPI Method      | Look for                                           |
|----------------------------------|-------------|-----------------|----------------------------------------------------|
| Webhook push — custom URL        | Required    | parseWebhook    | Platform allows configuring a custom webhook URL   |
| Fetch ticket messages            | Required    | getMessages     | GET messages/comments on ticket                    |
| Fetch ticket subject             | Required    | getSubject      | Subject/title field in ticket detail API           |
| Send reply                       | Required    | sendReply       | POST reply/comment to ticket                       |
| Read current tags/labels         | Required    | getTags         | GET ticket tags/labels                             |
| Apply tags/labels                | Required    | applyTags       | PUT/PATCH ticket tags                              |
| Webhook signature verification   | Recommended | parseWebhook    | HMAC-SHA256 header or signing secret               |
```

### Rationale

The SPI Method column makes explicit what each API capability maps to in the Ticket v2
codebase, so the assessor knows exactly which interface method will break if a capability
is missing or partial. The "custom URL" clarification removes ambiguity: any platform that
accepts a user-configured webhook URL is sufficient — Shulex appends its own token.

## Change 2: check-api — Feature 4 (Frontend Integration)

### Position in output

After Feature 3 (数据同步), before SUMMARY.

### Output format

```
FEATURE 4: 前端集成评估 (Frontend Integration)
─────────────────────────────────────────
（基于已分析的授权模式和 API 能力推导前端 Drawer 规格）

AUTH SECTION
授权方式: {OAuth 跳转 / API Key 填写 / 子域名+OAuth / 多步骤}
输入字段:
  - {字段名}: {用途} [必填/选填]
  ...
手工前置步骤（三方平台操作，前端展示引导）:
  ⚠️ {步骤描述}       ← 仅当有手工步骤时输出
  — 无手工前置步骤    ← 全自动时用此行

FEATURE SETTINGS SECTION
{每个 check-api 分析为可行的功能各列一项}
  - 工单 AI 回复: {可配置项，如 Agent 选择 / 处理范围 / 无需额外配置}
  - Livechat:     {可配置项 或 N/A}
  - 数据同步:     {可配置项 或 N/A}

MANUAL GUIDANCE（需在三方平台手工完成，前端展示操作引导）
  ⚠️ Webhook URL 配置: 前端展示 Shulex Webhook URL，提示用户在三方后台填入
  ⚠️ {其他手工步骤，如创建 OAuth App、开启 API 权限等}
  — 无手工步骤
```

### SUMMARY addition

```
前端集成:    {简评，如 "OAuth 跳转授权 + 1 项手工 Webhook 配置"}
```

## Change 3: flow-analyze — Frontend Aggregation Section

### Position in flow

After Phase C summary, before calling `intelli:report`.

### Content

Synthesizes authorization steps and manual configuration operations identified in Phase B
into the same AUTH SECTION / FEATURE SETTINGS SECTION / MANUAL GUIDANCE structure as
check-api's Feature 4. The assessor scans Phase B steps for:
- Credential/authorization steps → AUTH SECTION
- "Our system configuration" steps → FEATURE SETTINGS SECTION
- "Third-party admin console" steps → MANUAL GUIDANCE

Pass the resulting section to `intelli:report` as additional context alongside the
chain-mode flag.

## Change 4: intelli:report — Role-Scaled Frontend Sections

All four report files gain a **前端集成** section at the end, with depth increasing by role.

### pm.md — ASCII mockup + block-level labels

ASCII wireframe of the platform Drawer with labeled sections. One-line description per
block. Ends with a "需制作" summary (auth form / feature config panel / webhook display
component etc.).

Example mockup structure:
```
┌─────────────────────────────────────────┐
│  🔧 {Platform}                          │
├─────────────────────────────────────────┤
│  ◉ 授权                                 │
│    {输入字段}                            │
│    [连接 →]  ✓ 已授权                   │
├─────────────────────────────────────────┤
│  ⚙ 功能设置                             │
│  ┌──────────────────────────────────┐  │
│  │ {可用功能及其配置项}               │  │
│  └──────────────────────────────────┘  │
├─────────────────────────────────────────┤
│  ⚠ 手工操作（若有）                      │
│  {操作说明 + URL 展示}                  │
└─────────────────────────────────────────┘
```

### arch.md — Auth mechanism analysis + Section responsibility

- Authorization model: how credential flows from frontend input → ExternKey
- Auth section behavior: input fields, OAuth redirect, authorized/revoked states
- Feature settings section: which features, how they relate, no field-level detail
- Manual guidance: what needs to be shown and why (webhook URL, OAuth app creation, etc.)

### dev.md — Section list + fields + API dependencies

For each Drawer section:
- Field table (name, type, required, purpose)
- API calls (endpoint, method, response shape)
- State transitions (e.g., unauthenticated → authenticating → authenticated)
- Disabled mask conditions

### spec.md — Complete UI spec, ready for development

- All fields with validation rules (required, format, length)
- Full state machine for auth flow
- Complete API signatures (path, method, request body, response)
- Error handling (auth failure, network error, revoke confirmation)
- Loading states and transitions
- Component dependencies (references to existing mod/ components where applicable)

## Scope

Files to modify:
- `skills/check-api/SKILL.md` — Ticket v2 table + Feature 4 section
- `skills/flow-analyze/SKILL.md` — Frontend aggregation section after Phase C
- `skills/report/SKILL.md` — Role-scaled frontend section in all four report templates

No changes to `intelli:analyze`, `intelli:map-arch`, or `intelli:update-kb`.

## Non-Goals

- Changing the authorization model evaluation (Feature 0) — it stays as-is
- Adding frontend evaluation to `intelli:map-arch` — map-arch covers backend SPI only
- Generating actual frontend code — reports describe the spec, not implement it
