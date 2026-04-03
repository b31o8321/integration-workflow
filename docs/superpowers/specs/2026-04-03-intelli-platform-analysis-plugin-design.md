# Intelli Platform Analysis Plugin — Design Spec

**Date:** 2026-04-03  
**Project:** integration-workflow  
**Status:** Approved

---

## Overview

A standalone Claude Code plugin that analyzes third-party platform APIs and determines whether they can support the core features of the Shulex Intelli system. When a platform is deemed feasible, the plugin hands off to `superpowers:brainstorming` to begin implementation planning.

The plugin lives in `integration-workflow/` and is installed via symlink into `~/.claude/skills/intelli/`.

---

## Use Cases

- **Product / Delivery**: Quick feasibility check — can we support this platform at all?
- **Technical evaluation**: Detailed gap analysis before committing to integration work
- **Development kickoff**: After feasibility is confirmed, flow into design and implementation

---

## Plugin Structure

```
integration-workflow/
├── .claude-plugin/
│   └── plugin.json           # Plugin metadata
├── skills/
│   └── intelli/
│       ├── analyze/
│       │   └── SKILL.md      # Main orchestrator: collects input, drives phase checkpoints
│       ├── check-api/
│       │   └── SKILL.md      # Phase 1: raw platform API capability analysis
│       ├── map-arch/
│       │   └── SKILL.md      # Phase 2: map capabilities to intelli architecture
│       └── report/
│           └── SKILL.md      # Phase 3: generate feasibility report in two tiers
├── install.sh                # Symlinks skills/intelli → ~/.claude/skills/intelli
└── PLUGIN.md                 # User-facing plugin overview
```

---

## Installation

`install.sh` creates a symlink so changes in the repo are immediately reflected:

```bash
#!/bin/bash
SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$SKILLS_DIR"
ln -sf "$(pwd)/skills/intelli" "$SKILLS_DIR/intelli"
echo "Installed: ~/.claude/skills/intelli → $(pwd)/skills/intelli"
```

No GitHub repository or marketplace registration required.

---

## Execution Flow

```
User: /intelli:analyze [platform name / URL / file path / pasted content]
         │
         ▼
    [intelli:check-api]
    Collect platform info via: WebFetch (URL) | Read (file) | inline text
    Analyze capabilities across three feature dimensions
         │
         ▼
    ── CHECKPOINT A ──────────────────────────────────────────
    Display: Capability Matrix (✅ / ⚠️ / ❌ per feature)
    Ask: "继续进行架构映射分析？还是到此为止？"
    → Stop: output matrix, done  (e.g. PM/delivery quick check)
    → Continue ↓
    ──────────────────────────────────────────────────────────
         │
         ▼
    [intelli:map-arch]
    Map each capability to intelli's existing SPI/interfaces
    Identify gaps and implementation difficulty per checklist item
         │
         ▼
    ── CHECKPOINT B ──────────────────────────────────────────
    Display: Architecture mapping + gap list
    Ask: "生成完整可行性报告？"
    → Stop: output mapping, done
    → Continue ↓
    ──────────────────────────────────────────────────────────
         │
         ▼
    [intelli:report]
    Generate two-tier report:
      Tier 1 (PM/Delivery): traffic-light per feature + one-line verdict
      Tier 2 (Dev): gap list + effort level + integration checklist
    Save to: docs/platform-analysis/YYYY-MM-DD-{platform}.md
         │
         ▼
    ── CHECKPOINT C ──────────────────────────────────────────
    Ask: "进入实现阶段（调用 superpowers:brainstorming）？"
    → Stop: done
    → Continue → invoke superpowers:brainstorming
    ──────────────────────────────────────────────────────────
```

---

## Phase 1: `intelli:check-api` — Capability Matrix

### Input Handling

| Input Type | Mechanism |
|------------|-----------|
| URL | `WebFetch` to retrieve API documentation |
| Local file | `Read` tool (MD / PDF / JSON / OpenAPI spec) |
| Pasted text / description | Analyze inline content directly |

### Capability Dimensions

For each of the three Intelli features, the skill checks:

#### Feature 1: 工单 AI 回复 (Ticket AI Reply)
| Capability | Notes |
|------------|-------|
| Webhook push (inbound events) | Platform can notify us when a ticket is created/updated |
| Fetch ticket messages | API to retrieve conversation history |
| Send reply | API to post a message back to the ticket |
| Tag / label management | API to apply tags (for handoff/replied state) |
| Webhook signature verification | Optional but important for security |

#### Feature 2: Livechat 对接 (Live Chat Integration)
| Capability | Notes |
|------------|-------|
| Real-time message channel | WebSocket preferred; long-polling or webhook accepted |
| Receive messages (inbound) | Platform pushes or exposes new messages |
| Send messages (outbound) | API to write a message into a live session |
| Session/conversation lifecycle | Open, close, or transfer a chat session |

#### Feature 3: 数据同步 (Order / Product / Logistics Sync)
| Capability | Notes |
|------------|-------|
| Order query API | List / get orders with filters |
| Product query API | List / get product catalog |
| Logistics / tracking API | Shipment status, tracking numbers |
| Incremental pull (time range filter) | `updated_after` or equivalent — required for `ISyncService` |
| Pagination | Cursor or page-based — required for large datasets |

### Output: Capability Matrix

```
Platform: {Name}
Analyzed: {date}

┌─────────────────────────┬──────────┬──────────┬──────────┐
│ Capability              │ Ticket   │ Livechat │ DataSync │
├─────────────────────────┼──────────┼──────────┼──────────┤
│ Webhook / Event push    │    ✅    │    ⚠️    │    ❌    │
│ Fetch messages/data     │    ✅    │    ✅    │    ✅    │
│ ...                     │   ...    │   ...    │   ...    │
└─────────────────────────┴──────────┴──────────┴──────────┘

Legend: ✅ Supported  ⚠️ Partial / Workaround needed  ❌ Not available
```

---

## Phase 2: `intelli:map-arch` — Architecture Mapping

Maps each platform capability to the corresponding intelli interface or checklist item.

### Ticket AI Reply → TicketEngine V2 checklist

| intelli Requirement | Platform Capability | Status |
|--------------------|---------------------|--------|
| `TicketPlatformPlugin.parseWebhook()` | Webhook push + parseable payload | ✅/⚠️/❌ |
| `TicketOperations.getMessages()` | Fetch ticket messages API | |
| `TicketOperations.sendReply()` | Send reply API | |
| `TicketOperations.applyTags()` | Tag management API | |
| `TicketOperations.getTags()` | Read current tags | |
| Webhook signature verification | HMAC or equivalent | |
| `ExternKeySourceEnum` registration | Platform identifier exists | |

### Livechat → Livechat Engine checklist

| intelli Requirement | Platform Capability | Status |
|--------------------|---------------------|--------|
| Inbound message channel | WebSocket / Webhook / Polling | |
| Outbound message send | REST API or WebSocket | |
| Session open/close events | Lifecycle event notifications | |
| Message deduplication key | Unique message ID per event | |

### Data Sync → ISyncService checklist

| intelli Requirement | Platform Capability | Status |
|--------------------|---------------------|--------|
| `ISyncService` order pull | Order list API with time filter | |
| `ISyncService` product pull | Product/SKU API | |
| Logistics data | Tracking / shipment API | |
| Incremental window (`updatedAfter`) | Time-range filter param | |
| Pagination | Cursor or page+size | |
| Rate limit info | `X-RateLimit-*` headers or docs | |

### Output

Per-feature verdict with difficulty:
- **可行** — all required interfaces covered
- **部分可行** — workarounds exist, noting what needs custom handling
- **不可行** — one or more required interfaces missing with no feasible alternative

---

## Phase 3: `intelli:report` — Feasibility Report

### Tier 1 (PM / Delivery — ~1 page)

```
# {Platform} 接入可行性评估

日期: YYYY-MM-DD

## 结论

| 功能         | 结论     | 说明                     |
|--------------|----------|--------------------------|
| 工单AI回复   | ✅ 可行  | 标准 Webhook + 回复 API  |
| Livechat对接 | ⚠️ 部分可行 | 无 WebSocket，需轮询     |
| 数据同步     | ❌ 不可行 | 无订单增量拉取接口       |

## 建议
{one-paragraph recommendation}
```

### Tier 2 (Dev — full detail)

```
## 技术差距分析

### 工单AI回复
- [差距1] applyTags API 不支持批量 → 需逐条调用，注意频率
- ...

### 实现工作量
- 工单AI回复: 小（3–5天）
- Livechat:   中（1–2周）
- 数据同步:   不建议（缺口无解）

## 接入 Checklist（可直接使用）
[ ] ExternKeySourceEnum 注册
[ ] TicketPlatformPlugin 实现
...
```

### Save location

```
docs/platform-analysis/YYYY-MM-DD-{platform-name}.md
```

---

## Skill Invocation Map

| Command | Invokes |
|---------|---------|
| `/intelli:analyze` | Main orchestrator |
| `/intelli:check-api` | Standalone capability check (no flow) |
| `/intelli:map-arch` | Standalone arch mapping (requires prior matrix) |
| `/intelli:report` | Standalone report generation |

Each sub-skill can also be called independently when only part of the flow is needed.

---

## Out of Scope

- Auto-generating implementation code (that's superpowers:brainstorming's job)
- Storing historical analysis results beyond the saved markdown files
- Comparing multiple platforms against each other (single-platform analysis only)
