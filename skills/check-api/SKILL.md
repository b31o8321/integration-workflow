---
name: check-api
description: Analyze a third-party platform's raw API capabilities across three Intelli feature dimensions: Ticket AI Reply, Livechat, and Data Sync. Outputs a structured capability matrix. Optionally validates APIs with real calls if credentials are provided.
---

# intelli:check-api — Platform API Capability Analysis

## Purpose

Analyze a third-party platform's API and produce a structured capability matrix
showing which Intelli features it can support.

This skill is Phase 1 of the full analysis flow. It can also be used standalone
when you only need a quick capability snapshot.

## Input

Accept any of these input forms — detect which one the user provided:

1. **URL** — use WebFetch to retrieve the API documentation page
2. **Local file path** — use Read tool to load the file (supports .md, .pdf, .json, OpenAPI specs)
3. **Pasted content / platform name** — analyze inline text, or use WebSearch to find public API docs for the named platform

If the input is ambiguous, ask: "这是一个 URL、本地文件路径，还是平台名称/API描述？"

## Analysis Process

For each of the three feature dimensions below, evaluate the platform's API and
assign a status to each capability:

- ✅ **Supported** — clearly documented, straightforward to implement
- ⚠️ **Partial** — workaround possible but with caveats (note the caveat)
- ❌ **Not available** — no API exists for this; blocking if required

### Feature 1: 工单 AI 回复 (Ticket AI Reply)

| Capability | Required? | SPI Method | Look for |
|------------|-----------|------------|---------|
| Webhook push — custom URL | Required | parseWebhook | Platform allows configuring a custom webhook URL (POST to Shulex URL) |
| Fetch ticket messages | Required | getMessages | GET messages/comments on ticket |
| Fetch ticket subject | Required | getSubject | Subject/title field in ticket detail API |
| Send reply | Required | sendReply | POST reply/comment to ticket |
| Read current tags/labels | Required | getTags | GET ticket tags/labels |
| Apply tags/labels | Required | applyTags | PUT/PATCH ticket tags |
| Webhook signature verification | Recommended | parseWebhook | HMAC signature header or signing secret (e.g. HMAC-SHA256, X-Hub-Signature) |

> `parseWebhook` handles both webhook parsing and signature verification — it intentionally appears on two rows.

### Feature 2: Livechat 对接 (Live Chat Integration)

| Capability | Required? | Look for |
|------------|-----------|---------|
| Real-time inbound channel | Required | WebSocket API preferred; webhook or polling accepted |
| Send message outbound | Required | POST message to conversation/session |
| Session lifecycle events | Required | Open, close, transfer events |
| Unique message ID | Required | Deduplication key per message |

### Feature 0: 授权模式（Authorization Model）

在开始三维度分析之前，先评估授权模式。这直接影响方案能否落地。

重点区分以下两类：

| 类型 | 标志 | 说明 |
|------|------|------|
| **客户自助授权** | ✅ SELF_AUTH | 客户可以自行生成 API Key / OAuth Token，无需平台审核 |
| **需申请 Marketplace App** | 🚨 MARKETPLACE_APP | 需向平台官方提交开发者申请，经审核后才能对客户进行授权 |

Look for these signals that indicate MARKETPLACE_APP is required:
- "Apply to be a partner / ISV / developer"
- "Your app must be approved / reviewed / listed"
- "Submit app for review"
- "Public app" / "App Store listing" required for OAuth
- Restricted API access by approval (e.g., Amazon SP-API Reports, Meta Graph API advanced permissions)
- "Contact us to enable" / "Available upon request"

Look for these signals that indicate SELF_AUTH (customer can authorize directly):
- "Generate API Key in your account settings"
- "Create OAuth app with your own credentials"
- "Private app" / "Custom app" mode available
- Customer provides subdomain + API key / token

Assign one of:
- ✅ **SELF_AUTH** — 客户直接授权，无审核流程，不影响方案实施
- 🚨 **MARKETPLACE_APP** — 需官方申请/审核，**方案实施前置条件**，需在报告中重点标注
- ⚠️ **CONDITIONAL** — 部分 API 需审核（注明哪些能力受限）

### Feature 3: 数据同步 (Order / Product / Logistics Sync)

| Capability | Required? | Look for |
|------------|-----------|---------|
| Order list API | Required for order sync | GET /orders with filters |
| Product/SKU API | Required for product sync | GET /products |
| Logistics/tracking API | Required for logistics sync | GET shipments/tracking |
| Incremental pull (time filter) | Required | `updated_after`, `created_after`, or date range params |
| Pagination | Required | cursor-based or page+size |
| Rate limit documentation | Recommended | X-RateLimit headers or rate limit policy |

## Output Format

After analysis, output the capability matrix in this exact format:

```
Platform: {Platform Name}
Analyzed: {YYYY-MM-DD}
Source: {URL / file path / description}

CAPABILITY MATRIX
═══════════════════════════════════════════════════════════════

AUTHORIZATION MODEL
─────────────────────────────────────────
{✅ SELF_AUTH / 🚨 MARKETPLACE_APP / ⚠️ CONDITIONAL}

授权方式: {API Key / OAuth2 / JWT / Basic Auth}
凭证来源: {e.g. "客户在平台设置页自行生成 API Key" / "需向平台提交开发者申请，审核通过后发放 OAuth Client ID/Secret"}
{If MARKETPLACE_APP or CONDITIONAL:}
⚠️  申请要求: {描述申请流程，如 "需注册 Partner 账号，提交 App 审核，通常需 X 周"}
⚠️  受限能力: {哪些 API 需要审核才能访问，哪些可以直接使用}
⚠️  实施影响: {对方案排期的影响，如 "需提前 N 周开始申请，审核通过前无法集成测试"}

FEATURE 1: 工单 AI 回复 (Ticket AI Reply)
─────────────────────────────────────────
✅ Webhook push          — {brief note, e.g. "POST to configured URL on ticket create/update"}
✅ Fetch ticket messages — {note}
✅ Send reply            — {note}
✅ Read tags             — {note}
⚠️ Apply tags            — {note, e.g. "only supports one tag at a time, must loop"}
✅ Webhook signature     — {note}

FEATURE 2: Livechat 对接
─────────────────────────────────────────
✅ Inbound channel       — {note, e.g. "WebSocket at wss://..."}
✅ Send message          — {note}
⚠️ Session lifecycle     — {note}
✅ Unique message ID     — {note}

FEATURE 3: 数据同步
─────────────────────────────────────────
✅ Order API             — {note}
❌ Product API           — {note, e.g. "no product catalog endpoint documented"}
✅ Logistics API         — {note}
✅ Incremental pull      — {note, e.g. "supports updated_after param"}
✅ Pagination            — {note, e.g. "cursor-based"}
⚠️ Rate limits           — {note}

SUMMARY
═══════════════════════════════════════════════════════════════
授权模式:    {✅ SELF_AUTH / 🚨 MARKETPLACE_APP（需申请审核） / ⚠️ CONDITIONAL}
工单 AI 回复:  {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
Livechat 对接: {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
数据同步:      {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
{If MARKETPLACE_APP:}
🚨 注意: 接入前需完成 Marketplace App 申请，建议尽早启动审核流程。
```

## Optional: Live API Validation

After outputting the capability matrix, ask:

```
是否需要真实调用 API 进行验证？（需要提供授权凭证）

→ 是：请提供 API Key / Token（格式见下方说明）
→ 否：分析到此结束
```

If the user provides credentials, proceed with validation.

### Step 1: Identify Auth Method

From the API docs already analyzed, determine the platform's auth scheme:

| Auth Type | How to detect | Request format |
|-----------|--------------|----------------|
| Bearer Token | `Authorization: Bearer` in docs | `-H "Authorization: Bearer {token}"` |
| API Key Header | Custom header like `X-Api-Key`, `Api-Key` | `-H "{header-name}: {key}"` |
| Basic Auth | `Authorization: Basic` or username+password | `-u "{user}:{password}"` |
| Query Param | `?api_key=` or `?token=` in URL | Append to URL |
| OAuth2 | Access token after OAuth flow | `-H "Authorization: Bearer {access_token}"` |

Tell the user which auth type was detected and confirm the credential format before proceeding.

### Step 2: Classify Capabilities by Validation Type

Classify each capability into one of three types:

| Type | Handling |
|------|---------|
| **Read** | Execute directly with Bash/curl; if range params required, ask user first |
| **Write** | Generate curl command only — do NOT execute; user adjusts and runs manually |
| **Webhook** | Collect official setup docs; present for user to confirm manually |

Typical classification:

| Capability | Type |
|------------|------|
| Fetch ticket messages | Read |
| Read tags/labels | Read |
| Order / Product / Logistics API | Read |
| Rate limit headers | Read (check response headers) |
| Send reply | Write |
| Apply tags | Write |
| Webhook push | Webhook |
| WebSocket inbound | Webhook |
| Session lifecycle events | Webhook |

### Step 3: Handle Each Type

#### Read Operations

Before calling, check if the endpoint requires range/filter parameters (e.g. `start_time`, `shop_id`, `order_status`).
If required params are not obvious from docs, ask the user:

```
GET /orders 需要以下参数，请提供：
- shop_id（必填）：
- start_time（选填，建议填一个近期日期）：
```

Then execute with Bash tool:

```bash
curl -s -w "\nHTTP_STATUS:%{http_code}" \
  -H "Authorization: Bearer {token}" \
  "{base_url}/{endpoint}?limit=1{&user_params}"
```

Show the user: HTTP status + truncated response body (first 300 chars).

Interpret status:
- `200` / `201` — ✓ Verified
- `401` / `403` — ✗ Auth failed → stop all further calls, inform user
- `404` — ✗ Endpoint not found (don't change capability status)
- `429` — ✓ Exists, rate limited
- `5xx` — ⚠️ Inconclusive

#### Write Operations

Do NOT execute. Generate a curl command and present it clearly:

```
✏️  Send reply — 请手动执行以下命令验证：

curl -X POST "{base_url}/tickets/{ticket_id}/replies" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"body": "test reply from intelli validation"}'

⚠️  请将 {ticket_id} 替换为一个测试工单 ID，确认后告知结果。
```

Wait for the user to report the result before marking as verified.

#### Webhook Operations

Collect the relevant section from the API docs and present it:

```
🔗  Webhook push — 需人工确认配置：

文档摘录：
{paste the relevant webhook setup section from docs}

请确认：
1. 你的环境是否可以注册 Webhook URL？
2. 以上文档描述是否符合预期？

确认后将标记为 ✓ Verified。
```

### Step 4: Output Validation Results

After all checks, append to the capability matrix:

```
LIVE VALIDATION RESULTS
═══════════════════════════════════════════════════════════════
Auth method: {detected auth type}
Base URL:    {api base url}

READ (auto-executed)
✓ Fetch ticket messages — HTTP 200 · {"id":123,"subject":"..."...} (truncated)
✓ Read tags             — HTTP 200 · [{"id":1,"name":"urgent"}...] (truncated)
✓ Order API             — HTTP 200 · {"orders":[{"id":"O-001"...}]} (truncated)
✗ Product API           — HTTP 404 · endpoint not found

WRITE (curl generated, awaiting manual verification)
✓ Send reply            — 用户确认: HTTP 201 成功
? Apply tags            — 待用户验证

WEBHOOK (awaiting manual confirmation)
✓ Webhook push          — 用户确认: 文档描述符合预期，可配置
— WebSocket             — 用户确认: 平台不支持 WebSocket

验证结论: {overall summary}
```

## Standalone vs Orchestrated

- **Standalone** (`/intelli:check-api`): Output the matrix, offer validation, then stop.
- **Orchestrated** (called from `intelli:analyze`): Output the matrix, offer validation, then return control to the orchestrator for the checkpoint.
