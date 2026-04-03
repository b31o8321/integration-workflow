# Intelli Platform Analysis Plugin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin with 4 skills (`intelli:analyze`, `intelli:check-api`, `intelli:map-arch`, `intelli:report`) that analyze third-party platform APIs for Intelli compatibility and optionally hand off to superpowers:brainstorming.

**Architecture:** Four SKILL.md files under `skills/intelli/`, installed via symlink to `~/.claude/skills/intelli/`. The `analyze` skill orchestrates the other three in sequence with user checkpoints between each phase.

**Tech Stack:** Markdown skill files (SKILL.md format), bash install script, JSON plugin metadata.

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `skills/intelli/analyze/SKILL.md` | Create | Main orchestrator, checkpoint flow |
| `skills/intelli/check-api/SKILL.md` | Create | Phase 1: raw API capability matrix |
| `skills/intelli/map-arch/SKILL.md` | Create | Phase 2: map to intelli architecture |
| `skills/intelli/report/SKILL.md` | Create | Phase 3: two-tier feasibility report |
| `.claude-plugin/plugin.json` | Create | Plugin metadata |
| `install.sh` | Create | Symlink installer |
| `PLUGIN.md` | Create | User-facing overview |

---

## Task 1: Project Scaffold

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `install.sh`
- Create: `PLUGIN.md`

- [ ] **Step 1: Create plugin.json**

```json
{
  "name": "intelli",
  "description": "Intelli platform integration analysis — evaluates third-party platform APIs for Shulex Intelli compatibility",
  "version": "1.0.0",
  "author": {
    "name": "Shulex"
  }
}
```

Save to: `.claude-plugin/plugin.json`

- [ ] **Step 2: Create install.sh**

```bash
#!/bin/bash
set -e

SKILLS_DIR="$HOME/.claude/skills"
PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)/skills/intelli"

mkdir -p "$SKILLS_DIR"

if [ -L "$SKILLS_DIR/intelli" ]; then
  echo "Removing existing symlink: $SKILLS_DIR/intelli"
  rm "$SKILLS_DIR/intelli"
fi

ln -s "$PLUGIN_DIR" "$SKILLS_DIR/intelli"
echo "✓ Installed: ~/.claude/skills/intelli → $PLUGIN_DIR"
echo ""
echo "Available skills:"
echo "  /intelli:analyze    — full analysis flow with checkpoints"
echo "  /intelli:check-api  — standalone API capability check"
echo "  /intelli:map-arch   — standalone architecture mapping"
echo "  /intelli:report     — standalone report generation"
```

Save to: `install.sh`

- [ ] **Step 3: Make install.sh executable**

```bash
chmod +x install.sh
```

- [ ] **Step 4: Create PLUGIN.md**

```markdown
# Intelli Platform Analysis Plugin

Analyzes third-party platform APIs to determine whether they can support
Shulex Intelli's core features: Ticket AI Reply, Livechat integration,
and Order/Product/Logistics data sync.

## Installation

```bash
cd /path/to/integration-workflow
./install.sh
```

## Usage

### Full analysis flow (recommended)
```
/intelli:analyze <platform name, URL, file path, or paste API docs>
```
Walks through three phases with checkpoints — stop at any phase.

### Standalone skills
```
/intelli:check-api   — Phase 1 only: capability matrix
/intelli:map-arch    — Phase 2 only: intelli architecture mapping
/intelli:report      — Phase 3 only: feasibility report
```

## When to use which

| Audience | Command | Gets |
|----------|---------|------|
| PM / Delivery | `/intelli:analyze` → stop at Phase 1 | Capability matrix |
| Tech lead | `/intelli:analyze` → stop at Phase 2 | Gap analysis |
| Dev team | `/intelli:analyze` → full flow | Report + implementation kickoff |
```

Save to: `PLUGIN.md`

- [ ] **Step 5: Create skills directory structure**

```bash
mkdir -p skills/intelli/analyze
mkdir -p skills/intelli/check-api
mkdir -p skills/intelli/map-arch
mkdir -p skills/intelli/report
```

- [ ] **Step 6: Commit scaffold**

```bash
git init  # if not already a git repo
git add .claude-plugin/plugin.json install.sh PLUGIN.md
git commit -m "feat: plugin scaffold with install script"
```

---

## Task 2: `intelli:check-api` skill

**Files:**
- Create: `skills/intelli/check-api/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
---
name: check-api
description: Analyze a third-party platform's raw API capabilities across three Intelli feature dimensions: Ticket AI Reply, Livechat, and Data Sync. Outputs a structured capability matrix.
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

## Standalone vs Orchestrated

- **Standalone** (`/intelli:check-api`): Output the matrix and stop. Do not proceed further.
- **Orchestrated** (called from `intelli:analyze`): Output the matrix, then return control to the orchestrator for the checkpoint.
```

Save to: `skills/intelli/check-api/SKILL.md`

- [ ] **Step 2: Commit**

```bash
git add skills/intelli/check-api/SKILL.md
git commit -m "feat: add intelli:check-api skill"
```

---

## Task 3: `intelli:map-arch` skill

**Files:**
- Create: `skills/intelli/map-arch/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
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
```

Save to: `skills/intelli/map-arch/SKILL.md`

- [ ] **Step 2: Commit**

```bash
git add skills/intelli/map-arch/SKILL.md
git commit -m "feat: add intelli:map-arch skill"
```

---

## Task 4: `intelli:report` skill

**Files:**
- Create: `skills/intelli/report/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
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
```

Save to: `skills/intelli/report/SKILL.md`

- [ ] **Step 2: Create docs/platform-analysis directory**

```bash
mkdir -p docs/platform-analysis
touch docs/platform-analysis/.gitkeep
```

- [ ] **Step 3: Commit**

```bash
git add skills/intelli/report/SKILL.md docs/platform-analysis/.gitkeep
git commit -m "feat: add intelli:report skill"
```

---

## Task 5: `intelli:analyze` orchestrator skill

**Files:**
- Create: `skills/intelli/analyze/SKILL.md`

- [ ] **Step 1: Create SKILL.md**

```markdown
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
```

Save to: `skills/intelli/analyze/SKILL.md`

- [ ] **Step 2: Commit**

```bash
git add skills/intelli/analyze/SKILL.md
git commit -m "feat: add intelli:analyze orchestrator skill"
```

---

## Task 6: Install and verify

- [ ] **Step 1: Run install script**

```bash
cd /Users/norman/development/integration-workflow
./install.sh
```

Expected output:
```
✓ Installed: ~/.claude/skills/intelli → /Users/norman/development/integration-workflow/skills/intelli
```

- [ ] **Step 2: Verify symlink**

```bash
ls -la ~/.claude/skills/intelli
```

Expected: a symlink pointing to `integration-workflow/skills/intelli`

- [ ] **Step 3: Verify skill files are visible**

```bash
ls ~/.claude/skills/intelli/
```

Expected:
```
analyze/
check-api/
map-arch/
report/
```

- [ ] **Step 4: Final commit**

```bash
git add .
git commit -m "chore: complete plugin v1.0.0"
```

---

## Self-Review Notes

- All SKILL.md files use the `---\nname:\ndescription:\n---` frontmatter format matching superpowers conventions ✅
- Each sub-skill has a "Standalone vs Orchestrated" section so they work both ways ✅
- Checkpoints use Chinese text matching the intended audience ✅
- All three intelli features are covered in every phase ✅
- Report checklist references actual intelli interface names from TicketEngine V2 docs ✅
- install.sh handles re-run gracefully (removes existing symlink first) ✅
