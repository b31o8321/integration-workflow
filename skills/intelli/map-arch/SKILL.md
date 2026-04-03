---
name: map-arch
description: Maps a platform's API capabilities (from intelli:check-api) to the Shulex Intelli architecture — TicketEngine V2 SPI, Livechat engine, and ISyncService interfaces. Identifies gaps and implementation difficulty.
---

# intelli:map-arch — Architecture Mapping

## Purpose

Take the capability matrix from `intelli:check-api` and map each capability to
the corresponding Intelli interface or checklist item. Identify what is missing
and how hard each gap would be to work around.

This is Phase 2 of the full analysis flow. Can also be used standalone if you
already have a capability matrix.

## Input

Either:
- The capability matrix output from `intelli:check-api` (if called from `intelli:analyze`)
- A user-provided description of what the platform supports (if used standalone)

## Mapping Tables

### Ticket AI Reply → TicketEngine V2 SPI

Map each platform capability to the TicketEngine V2 interface requirement:

| intelli Interface | Maps To | Status | Notes |
|-------------------|---------|--------|-------|
| `TicketPlatformPlugin.parseWebhook()` | Webhook push + parseable JSON payload | | |
| `TicketPlatformPlugin.extractCredentialKey()` | Token in URL path or header | | |
| `TicketOperations.getMessages()` | Fetch ticket messages/comments API | | |
| `TicketOperations.getTags()` | Read current ticket tags API | | |
| `TicketOperations.getSubject()` | Ticket title/subject field | | |
| `TicketOperations.sendReply()` | POST reply/comment API | | |
| `TicketOperations.applyTags()` | Add tags to ticket API | | |
| Webhook signature verification | HMAC header + signing secret | | |
| `ExternKeySourceEnum` registration | Unique platform identifier | Always ✅ | Add enum value |

Fill each Status cell with: ✅ / ⚠️ (with workaround note) / ❌ (blocking gap)

### Livechat → Livechat Engine

| intelli Requirement | Maps To | Status | Notes |
|--------------------|---------|--------|-------|
| Inbound message delivery | WebSocket push / Webhook / Polling | | Prefer WebSocket |
| Outbound message send | REST POST or WebSocket send | | |
| Session open event | Conversation started event | | |
| Session close/transfer | Close or handoff event | | |
| Message dedup key | Unique message ID field | | |

### Data Sync → ISyncService

| intelli Requirement | Maps To | Status | Notes |
|--------------------|---------|--------|-------|
| Order incremental pull | `updatedAfter` / date range filter on order list | | |
| Order pagination | Cursor or page+size on order list | | |
| Product incremental pull | `updatedAfter` filter on product list | | |
| Product pagination | Cursor or page+size on product list | | |
| Logistics/tracking pull | Shipment status API | | |
| Rate limit handling | Documented rate limits or `X-RateLimit-*` headers | | |

## Gap Assessment

For each ❌ or ⚠️ item, classify the gap:

- **Minor** — workaround adds <1 day of work (e.g., loop instead of batch tag apply)
- **Medium** — workaround adds 2–5 days (e.g., implement polling instead of WebSocket)
- **Blocking** — no feasible workaround; feature cannot be implemented

## Output Format

```
ARCHITECTURE MAPPING: {Platform Name}
═══════════════════════════════════════════════════════════════

TICKET AI REPLY — TicketEngine V2
─────────────────────────────────────────
✅ parseWebhook()          — standard POST webhook, JSON payload
✅ getMessages()           — GET /tickets/{id}/comments
⚠️ applyTags()             — API only sets one tag per call [Minor gap: loop required]
✅ sendReply()             — POST /tickets/{id}/comments
✅ getTags() / getSubject() — included in ticket detail response
✅ Webhook signature       — X-Hub-Signature-256 HMAC

LIVECHAT
─────────────────────────────────────────
⚠️ Inbound channel         — no WebSocket; must use webhook [Medium gap: webhook polling fallback]
✅ Outbound send           — POST /conversations/{id}/messages
⚠️ Session lifecycle       — no close event, only open [Minor gap: timeout-based close]
✅ Message dedup key       — message.id field

DATA SYNC
─────────────────────────────────────────
✅ Order pull              — GET /orders?updated_after=...&page=1&per_page=50
❌ Product pull            — no product catalog endpoint [Blocking: cannot sync products]
✅ Logistics               — GET /shipments?order_id=...
✅ Pagination              — cursor-based on all list endpoints
⚠️ Rate limits             — 100 req/min documented; no headers [Minor: add sleep on 429]

FEASIBILITY VERDICT
═══════════════════════════════════════════════════════════════
工单 AI 回复:  ⚠️ 部分可行 — 1 Minor gap (tag loop)
Livechat 对接: ⚠️ 部分可行 — 1 Medium gap (no WebSocket), 1 Minor gap
数据同步:      ⚠️ 部分可行 — 1 Blocking gap (no product API); order+logistics sync feasible
```

## Standalone vs Orchestrated

- **Standalone** (`/intelli:map-arch`): Output the mapping and stop.
- **Orchestrated** (called from `intelli:analyze`): Output the mapping, then return control to the orchestrator for the checkpoint.
