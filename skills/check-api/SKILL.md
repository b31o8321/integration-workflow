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

| Capability | Required? | Look for |
|------------|-----------|---------|
| Webhook push (inbound events) | Required | Webhook/event subscription docs |
| Fetch ticket messages | Required | GET messages/comments on ticket |
| Send reply | Required | POST reply/comment to ticket |
| Read current tags/labels | Required | GET ticket tags |
| Apply tags/labels | Required | PUT/PATCH ticket tags |
| Webhook signature verification | Recommended | HMAC-SHA256 header, signing secret |

### Feature 2: Livechat 对接 (Live Chat Integration)

| Capability | Required? | Look for |
|------------|-----------|---------|
| Real-time inbound channel | Required | WebSocket API preferred; webhook or polling accepted |
| Send message outbound | Required | POST message to conversation/session |
| Session lifecycle events | Required | Open, close, transfer events |
| Unique message ID | Required | Deduplication key per message |

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
工单 AI 回复:  {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
Livechat 对接: {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
数据同步:      {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
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

### Step 2: Select Validation Endpoints

Choose the safest, most representative **read-only** endpoint for each capability.
Prefer list endpoints with small page size (`limit=1` / `per_page=1`) to minimize side effects.
**Never call write endpoints** (POST reply, apply tags, etc.) — only validate read/existence.

Priority endpoints to validate:

| Capability | Suggested endpoint |
|------------|-------------------|
| Fetch ticket messages | GET /tickets (or /conversations) with limit=1 |
| Read tags | GET /tags or GET /labels |
| Order API | GET /orders with limit=1 |
| Product API | GET /products with limit=1 |
| Logistics API | GET /shipments with limit=1 |

Skip validation for: Webhook push (can't test passively), Send reply, Apply tags (write ops), WebSocket (needs persistent connection).

### Step 3: Execute Validation Calls

Use the Bash tool to run curl for each selected endpoint. Template:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer {token}" \
  "{base_url}/{endpoint}"
```

Interpret HTTP status:
- `200` / `201` — ✓ Verified: endpoint exists and credentials work
- `401` / `403` — ✗ Auth failed: endpoint exists but credentials rejected
- `404` — ✗ Not found: endpoint URL might be wrong (don't mark capability as unavailable)
- `429` — ✓ Exists (rate limited): endpoint works, just throttled
- `5xx` — ⚠️ Server error: inconclusive

### Step 4: Output Validation Results

Append a validation section to the capability matrix:

```
LIVE VALIDATION RESULTS
═══════════════════════════════════════════════════════════════
Auth method: {detected auth type}
Base URL:    {api base url}

✓ Fetch ticket messages — HTTP 200 (GET /tickets?limit=1)
✓ Read tags             — HTTP 200 (GET /tags)
✓ Order API             — HTTP 200 (GET /orders?limit=1)
✗ Product API           — HTTP 404 (GET /products — endpoint not found)
✓ Logistics API         — HTTP 200 (GET /shipments?limit=1)
— Send reply            — skipped (write operation)
— Webhook push          — skipped (cannot test passively)

验证结论: 凭证有效，核心读取接口均可访问。
```

If any `401`/`403` are returned: stop and inform the user the credentials are invalid, do not continue calling other endpoints.

## Standalone vs Orchestrated

- **Standalone** (`/intelli:check-api`): Output the matrix, offer validation, then stop.
- **Orchestrated** (called from `intelli:analyze`): Output the matrix, offer validation, then return control to the orchestrator for the checkpoint.
