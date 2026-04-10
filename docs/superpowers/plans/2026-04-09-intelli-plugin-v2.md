# Intelli Plugin v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the intelli plugin from a fixed three-dimension capability matrix to a dual-mode analysis system that supports business flow validation with API-level detail and documentation links.

**Architecture:** Add a `flow-analyze` skill for business chain validation, an `update-kb` skill for maintaining system capability knowledge, and a `knowledge-base/` directory as a shared capability registry. Modify `analyze` to present mode selection, and `report` to support the new chain report format.

**Tech Stack:** Claude Code skills (SKILL.md markdown files), bash (install.sh)

**Spec:** `docs/superpowers/specs/2026-04-09-intelli-plugin-v2-design.md`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `knowledge-base/README.md` | Maintenance guide for knowledge-base |
| Create | `knowledge-base/intelli-capabilities.md` | Intelli SPI interface + supported platforms registry |
| Create | `knowledge-base/shulex-gpt-capabilities.md` | shulex_gpt AI capability registry |
| Create | `skills/flow-analyze/SKILL.md` | Business flow validation skill (Phase A/B/C) |
| Create | `skills/update-kb/SKILL.md` | Codebase analysis → knowledge-base update skill |
| Modify | `skills/analyze/SKILL.md` | Add mode selection to Phase 1 |
| Modify | `skills/report/SKILL.md` | Add chain mode report format section |
| Modify | `install.sh` | Add version consistency check |
| Modify | `README.md` | Document both modes + version bump rules |
| Modify | `package.json` | Bump version to 2.0.0 |

---

## Task 1: knowledge-base 目录和占位文件

**Files:**
- Create: `knowledge-base/README.md`
- Create: `knowledge-base/intelli-capabilities.md`
- Create: `knowledge-base/shulex-gpt-capabilities.md`

- [ ] **Step 1: 创建 knowledge-base/README.md**

内容如下（完整写入）：

```markdown
# Knowledge Base — 系统能力注册表

本目录记录 Intelli 和 shulex_gpt 的现有能力，供 `intelli:flow-analyze` 在链路验证时参照。

## 维护方式

运行 `/intelli:update-kb`（需要代码库通过 `/add-dir` 加入上下文）可自动分析并更新本目录文件。

每次更新后必须 bump `package.json` 版本号并 push，否则其他用户安装插件时不会拉取新版本。

## 版本 Bump 规则

| 变更类型 | 版本号 |
|---------|--------|
| 知识库更新、措辞修正 | x.x.N（patch） |
| 新增功能、流程调整 | x.N.0（minor） |
| 架构重构 | N.0.0（major） |

## 文件说明

| 文件 | 内容 |
|------|------|
| `intelli-capabilities.md` | Intelli SPI 接口实现状态 + 已接入平台列表 |
| `shulex-gpt-capabilities.md` | shulex_gpt AI 能力清单（语音/NLU/工具调用） |
```

- [ ] **Step 2: 创建 knowledge-base/intelli-capabilities.md**

内容如下（占位，等待 `update-kb` 填充真实数据）：

```markdown
# Intelli 系统能力

> 最后更新: 2026-04-09（占位版本，请运行 /intelli:update-kb 更新真实数据）

## TicketEngine V2 SPI

| 接口方法 | 状态 | 备注 |
|---------|------|------|
| `parseWebhook()` | ✅ | |
| `extractCredentialKey()` | ✅ | |
| `getMessages()` | ✅ | |
| `getTags()` | ✅ | |
| `getSubject()` | ✅ | |
| `sendReply()` | ✅ | |
| `applyTags()` | ✅ | |

## 已接入平台（TicketEngine）

| 平台 | 状态 | 备注 |
|------|------|------|
| Zendesk | ✅ | |
| Freshdesk | ✅ | |
| （更多平台请运行 update-kb 更新） | | |

## Livechat Engine

| 能力 | 状态 | 备注 |
|------|------|------|
| Webhook 接收模式 | ✅ | |
| WebSocket 接收模式 | ❌ | 未实现 |
| Voice Session Manager | ❌ | 未实现 |
| 出站消息发送 | ✅ | |
| Session 生命周期管理 | ✅ | |

## ISyncService

| 同步类型 | 状态 | 备注 |
|---------|------|------|
| 订单同步 | ✅ | |
| 商品同步 | ✅ | |
| 物流同步 | ⚠️ | 部分支持 |
```

- [ ] **Step 3: 创建 knowledge-base/shulex-gpt-capabilities.md**

内容如下（占位）：

```markdown
# shulex_gpt AI 能力

> 最后更新: 2026-04-09（占位版本，请运行 /intelli:update-kb 更新真实数据）

## 语音处理

| 能力 | 状态 | 备注 |
|------|------|------|
| ASR（语音转文字） | ✅ | 支持 Whisper / 云端 ASR |
| TTS（文字转语音） | ✅ | 支持中文 |
| 实时流式 ASR | ⚠️ | 延迟待测试 |

## 意图识别 / NLU

| 意图类型 | 状态 | 备注 |
|---------|------|------|
| 预约意图 | ✅ | |
| 取消/改期意图 | ✅ | |
| （更多意图请运行 update-kb 更新） | | |

## Tool Call

| 能力 | 状态 | 备注 |
|------|------|------|
| OpenAI tool call 格式 | ✅ | |
| 最大并发 tool 数 | ⚠️ | 请运行 update-kb 确认 |

## 对话状态管理

| 能力 | 状态 | 备注 |
|------|------|------|
| 多轮对话状态维护 | ✅ | |
| Voice Session Manager | ❌ | 未实现 |
```

- [ ] **Step 4: 验证文件创建正确**

```bash
ls knowledge-base/
# 预期输出: README.md  intelli-capabilities.md  shulex-gpt-capabilities.md
```

- [ ] **Step 5: Commit**

```bash
git add knowledge-base/
git commit -m "feat: add knowledge-base directory with placeholder capability files"
```

---

## Task 2: `intelli:update-kb` Skill

**Files:**
- Create: `skills/update-kb/SKILL.md`

- [ ] **Step 1: 创建 skills/update-kb/SKILL.md**

完整内容如下：

````markdown
---
name: update-kb
description: Analyze shulex_intelli and/or shulex_gpt codebases and update the plugin's knowledge-base capability registry. Requires /add-dir to load code into context first.
version: 1.0.0
---

# intelli:update-kb — 系统能力知识库更新

## Purpose

分析 shulex_intelli 和 shulex_gpt 代码库，更新 `knowledge-base/` 中的能力注册表。
更新后其他用户重装插件即可获得最新的系统能力信息，无需直接访问代码库。

## Pre-requisite Check

首先检查当前会话中可用的代码库：

```
检测上下文中的代码库...
```

使用 Glob 工具扫描已加载目录：
- 若找到 shulex_intelli → 分析 Intelli 能力
- 若找到 shulex_gpt → 分析 GPT 能力
- 若均未找到 → 输出以下提示并停止：

```
未检测到代码库。请先执行：

/add-dir <shulex_intelli 路径>
/add-dir <shulex_gpt 路径>

至少添加一个代码库后再运行 /intelli:update-kb。
```

## Analysis: shulex_intelli

若检测到 shulex_intelli，执行以下分析：

### 1. TicketEngine V2 SPI 接口实现状态

搜索 `TicketOperations` 接口定义，确认以下方法是否存在实现：
- `parseWebhook()`
- `extractCredentialKey()`
- `getMessages()`
- `getTags()`
- `getSubject()`
- `sendReply()`
- `applyTags()`

### 2. 已接入平台

搜索 `ExternKeySourceEnum`，列出所有已注册的平台枚举值。
搜索 `TicketPlatformPlugin` 的所有实现类，确认哪些平台已接入。

### 3. Livechat Engine 状态

搜索 Livechat 相关模块，确认：
- Webhook 接收模式实现状态
- WebSocket 接收模式实现状态
- Voice Session Manager 实现状态
- 出站消息发送实现状态

### 4. ISyncService 状态

搜索 `ISyncService` 实现类，列出已支持的同步类型。

## Analysis: shulex_gpt

若检测到 shulex_gpt，执行以下分析：

### 1. 语音处理能力

搜索 ASR、TTS、语音流处理相关模块，确认：
- ASR 支持的引擎（Whisper / 云端等）
- TTS 支持语言
- 是否支持实时流式 ASR 及延迟水平

### 2. 意图识别 / NLU

搜索意图识别相关模块，列出已支持的意图类型。

### 3. Tool Call 支持

搜索 tool call / function call 相关实现，确认：
- 支持的格式（OpenAI / 其他）
- 最大并发 tool 数限制

### 4. 对话状态管理

搜索对话状态管理模块，确认多轮对话状态维护能力。

## Update knowledge-base Files

分析完成后，更新对应文件：

1. 读取 `knowledge-base/intelli-capabilities.md`（若分析了 shulex_intelli）
2. 读取 `knowledge-base/shulex-gpt-capabilities.md`（若分析了 shulex_gpt）
3. 对比分析结果与现有内容，更新变更项
4. 在文件头部更新"最后更新"日期
5. 新增能力标注 `NEW`，状态变更的标注 `UPDATED`

## Post-Update Instructions

更新完成后输出：

```
knowledge-base 已更新：
{列出变更的文件和变更数量}

后续步骤：
1. 检查变更内容是否符合预期：
   git diff knowledge-base/

2. Bump package.json 版本号（patch 级别）：
   将 "version" 从 X.X.N 改为 X.X.N+1

3. Commit 并 push：
   git add knowledge-base/ package.json
   git commit -m "chore: update knowledge-base capabilities"
   git push

4. 团队成员重装插件获取最新版本：
   /plugin install intelli@intelli
   /reload-plugins
```
````

- [ ] **Step 2: 验证文件内容**

```bash
head -5 skills/update-kb/SKILL.md
# 预期：--- name: update-kb ...
```

- [ ] **Step 3: Commit**

```bash
git add skills/update-kb/SKILL.md
git commit -m "feat: add intelli:update-kb skill for knowledge-base maintenance"
```

---

## Task 3: `intelli:flow-analyze` Skill

**Files:**
- Create: `skills/flow-analyze/SKILL.md`

- [ ] **Step 1: 创建 skills/flow-analyze/SKILL.md**

完整内容如下：

````markdown
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
| ❌ 阻断 | 三方 API 明确不存在，或有根本性技术限制无法绕过 |

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
- 阻断的 Step: N 个（Step {编号列表}）

关键阻断点: {若无则写"无硬性阻断"}

主要前置条件:
{列出所有"有条件"Step 的确认事项，每条一行}

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
````

- [ ] **Step 2: 验证文件**

```bash
head -5 skills/flow-analyze/SKILL.md
# 预期：--- name: flow-analyze ...
wc -l skills/flow-analyze/SKILL.md
# 预期：> 100 行
```

- [ ] **Step 3: Commit**

```bash
git add skills/flow-analyze/SKILL.md
git commit -m "feat: add intelli:flow-analyze skill for business chain validation"
```

---

## Task 4: 修改 `intelli:analyze` — 加入模式选择

**Files:**
- Modify: `skills/analyze/SKILL.md`

- [ ] **Step 1: 在 Phase 1 末尾追加模式选择**

在 `skills/analyze/SKILL.md` 的 Phase 1 部分（当前第 22–37 行）末尾，在 `---` 之前插入以下内容：

```markdown
收集完以上信息后，询问分析模式：

```
你希望进行哪种分析？

→ 1. 标准能力评估
      输出三维度能力矩阵（工单AI回复 / Livechat对接 / 数据同步）
      适合：快速判断平台是否满足 Intelli 标准接入要求

→ 2. 业务链路验证
      基于你的业务目标，逐段验证技术链路可行性（API 级别，附文档链接）
      适合：有明确业务场景，需要知道端到端能否跑通
```

- 选 1：继续现有 Phase 2–5 流程（三维度标准分析）
- 选 2：调用 `intelli:flow-analyze` skill，传入业务背景和平台信息，
         然后由 flow-analyze 完整执行链路验证流程
```

- [ ] **Step 2: 更新 SKILL.md frontmatter 中的 description**

将 description 更新为：

```
description: Full Intelli platform analysis flow. Phase 1 collects business context and offers two modes: (1) standard three-dimension capability matrix, or (2) business flow validation with API-level detail and doc links. Use this as the single entry point for all platform evaluations.
```

- [ ] **Step 3: 验证修改**

```bash
grep -n "模式\|flow-analyze\|标准能力评估\|业务链路验证" skills/analyze/SKILL.md
# 预期：找到模式选择相关行
```

- [ ] **Step 4: Commit**

```bash
git add skills/analyze/SKILL.md
git commit -m "feat: add mode selection to intelli:analyze Phase 1 (standard vs flow)"
```

---

## Task 5: 修改 `intelli:report` — 支持链路模式

**Files:**
- Modify: `skills/report/SKILL.md`

- [ ] **Step 1: 在文件末尾追加链路模式报告说明**

在 `skills/report/SKILL.md` 的 `## Standalone vs Orchestrated` 节之前插入：

```markdown
## Chain Mode Report (链路模式报告)

当被 `intelli:flow-analyze` 调用时，生成链路模式报告而非三维度报告。

链路模式报告保存至：`docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}.md`

报告包含三个部分：

**一、链路总览（PM / 交付用）**
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
```

- [ ] **Step 2: 验证修改**

```bash
grep -n "Chain Mode\|链路模式\|flow-analyze" skills/report/SKILL.md
# 预期：找到链路模式相关段落
```

- [ ] **Step 3: Commit**

```bash
git add skills/report/SKILL.md
git commit -m "feat: add chain mode report format to intelli:report"
```

---

## Task 6: 基础设施更新

**Files:**
- Modify: `install.sh`
- Modify: `README.md`
- Modify: `package.json`

- [ ] **Step 1: 更新 install.sh，加版本一致性检查**

在 `install.sh` 末尾的 echo 输出部分，追加以下内容（在最后一行 echo 之后）：

```bash
echo ""
echo "可用 skills:"
echo "  /intelli:analyze     — 平台分析入口（标准模式 + 链路模式）"
echo "  /intelli:flow-analyze — 业务链路验证（独立使用）"
echo "  /intelli:check-api   — 独立 API 能力检查"
echo "  /intelli:map-arch    — 独立架构映射"
echo "  /intelli:report      — 独立报告生成"
echo "  /intelli:update-kb   — 更新系统能力知识库（需 /add-dir 代码库）"
echo ""
echo "⚠️  版本管理提醒："
echo "   修改任何 SKILL.md 或 knowledge-base/ 文件后，必须 bump package.json 版本号。"
echo "   Patch（知识库/措辞）: x.x.N | Minor（新功能）: x.N.0 | Major（架构）: N.0.0"
echo ""

# 版本一致性检查
CACHE_PKG=$(ls "$HOME/.claude/plugins/cache/intelli/intelli/"*/package.json 2>/dev/null | head -1)
if [ -n "$CACHE_PKG" ]; then
  CACHE_VERSION=$(grep '"version"' "$CACHE_PKG" | grep -o '[0-9][0-9.]*' | head -1)
  REPO_VERSION=$(grep '"version"' "${REPO_DIR}/package.json" | grep -o '[0-9][0-9.]*' | head -1)
  if [ "$CACHE_VERSION" != "$REPO_VERSION" ]; then
    echo "⚠️  版本不一致：plugin cache=$CACHE_VERSION，repo=$REPO_VERSION"
    echo "   请在 Claude Code 中执行：/plugin install intelli@intelli && /reload-plugins"
  else
    echo "✓ 版本一致：$REPO_VERSION"
  fi
fi
```

- [ ] **Step 2: 测试 install.sh 语法**

```bash
bash -n install.sh
# 预期：无输出（语法正确）
```

- [ ] **Step 3: 更新 README.md 的使用方式章节**

将 README.md 中"## 使用方式"章节替换为：

```markdown
## 使用方式

### 入口命令

```
/intelli:analyze <平台名称 / API 文档 URL / 本地文件路径>
```

Phase 1 收集业务背景后，选择分析模式：

**模式一：标准能力评估**
```
Phase 1: 业务场景收集 + 模式选择
Phase 2: API 能力检查    →  三维度能力矩阵
Phase 3: 架构映射        →  接口差距分析
Phase 4: 偏差评估        →  直接套用 / 简单改造 / 新链路设计
Phase 5: 可行性报告      →  研发 checklist + 工作量评估
```
适合：快速判断平台是否满足 Intelli 标准接入要求（工单/Livechat/数据同步）

**模式二：业务链路验证**
```
Phase 1:    业务场景收集 + 模式选择
Phase A:    AI 推导技术链路  →  用户确认/修正
Phase B:    逐段 API 验证    →  API端点 + 文档链接 + 系统能力对照
Phase C:    链路可行性总结   →  有条件/需开发 附三方资料
报告生成:   链路可行性报告   →  PM总览 + 研发详情 + 实现checklist
```
适合：有明确业务场景，需要知道端到端能否跑通

### 单独执行各阶段

```
/intelli:flow-analyze  — 单独运行业务链路验证
/intelli:check-api     — 仅输出能力矩阵（标准模式快速判断）
/intelli:map-arch      — 仅做架构映射（需已有能力矩阵）
/intelli:report        — 仅生成报告
/intelli:update-kb     — 更新系统能力知识库（需 /add-dir 代码库）
```
```

- [ ] **Step 4: 更新 README.md，追加版本管理章节**

在 README.md 末尾追加：

```markdown
## 版本管理（维护者必读）

修改任何 `SKILL.md` 或 `knowledge-base/` 文件后，**必须** bump `package.json` 版本号：

| 变更类型 | 版本号 |
|---------|--------|
| 知识库更新、措辞修正 | x.x.N（patch） |
| 新增功能、流程调整 | x.N.0（minor） |
| 架构重构 | N.0.0（major） |

版本号不 bump 则 `/reload-plugins` 不会重新拉取，用户拿到的仍是旧版本。
```

- [ ] **Step 5: Bump package.json 到 2.0.0**

将 `package.json` 的 version 字段改为：

```json
{
    "name": "intelli",
    "version": "2.0.0",
    "description": "Intelli platform integration analysis — dual-mode: standard capability matrix or business flow validation with API-level detail"
}
```

- [ ] **Step 6: 验证所有变更**

```bash
git diff --stat
# 预期：install.sh, README.md, package.json 均有改动
bash -n install.sh
# 预期：无输出
grep '"version"' package.json
# 预期："version": "2.0.0"
```

- [ ] **Step 7: Commit 并 push**

```bash
git add install.sh README.md package.json
git commit -m "feat: v2.0.0 — dual-mode analysis, knowledge-base, flow-analyze skill

- intelli:analyze now offers standard vs flow validation mode in Phase 1
- intelli:flow-analyze: business chain validation with API-level detail + doc links
- intelli:update-kb: codebase analysis → knowledge-base update
- knowledge-base/: intelli + shulex_gpt capability registry
- install.sh: version consistency check
- README: updated usage docs + version management guide"
git push
```

---

## 自检结果

| Spec 要求 | 对应 Task |
|-----------|----------|
| intelli:analyze Phase 1 加模式选择 | Task 4 |
| intelli:flow-analyze skill（Phase A/B/C） | Task 3 |
| intelli:update-kb skill | Task 2 |
| knowledge-base 目录 + 两个能力文件 | Task 1 |
| intelli:report 支持链路模式 | Task 5 |
| install.sh 版本一致性检查 | Task 6 |
| README 更新 + 版本管理章节 | Task 6 |
| package.json → 2.0.0 | Task 6 |

所有 Spec 要求均有对应 Task，无遗漏。
