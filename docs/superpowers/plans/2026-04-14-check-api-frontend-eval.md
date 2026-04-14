# check-api Ticket v2 Alignment + Frontend Evaluation Dimension

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `check-api` to align with Ticket v2 SPI and add a Frontend Integration evaluation dimension across all three affected skill files.

**Architecture:** Three skill SKILL.md files are modified in isolation — `check-api` gets the new capability table and Feature 4 analysis section; `flow-analyze` gets a frontend aggregation section after Phase C; `report` gets role-scaled frontend sections added to all eight report templates (4 standard + 4 chain mode).

**Tech Stack:** Markdown skill files in `skills/` directory; edited with the Edit tool.

---

## Task 1: check-api — Update 工单 AI 回复 Table

**Files:**
- Modify: `skills/check-api/SKILL.md`

- [ ] **Step 1: Read the current file**

  Run Read on `skills/check-api/SKILL.md` to confirm current table content and line numbers before editing.

- [ ] **Step 2: Replace the Feature 1 table**

  Find and replace the entire Feature 1 table. The old_string to match:

  ```
  ### Feature 1: 工单 AI 回复 (Ticket AI Reply)

  | Capability | Required? | Look for |
  |------------|-----------|---------|
  | Webhook push (inbound events) | Required | Webhook/event subscription docs |
  | Fetch ticket messages | Required | GET messages/comments on ticket |
  | Send reply | Required | POST reply/comment to ticket |
  | Read current tags/labels | Required | GET ticket tags |
  | Apply tags/labels | Required | PUT/PATCH ticket tags |
  | Webhook signature verification | Recommended | HMAC-SHA256 header, signing secret |
  ```

  Replace with:

  ```
  ### Feature 1: 工单 AI 回复 (Ticket AI Reply)

  | Capability | Required? | SPI Method | Look for |
  |------------|-----------|------------|---------|
  | Webhook push — custom URL | Required | parseWebhook | Platform allows configuring a custom webhook URL (POST to Shulex URL) |
  | Fetch ticket messages | Required | getMessages | GET messages/comments on ticket |
  | Fetch ticket subject | Required | getSubject | Subject/title field in ticket detail API |
  | Send reply | Required | sendReply | POST reply/comment to ticket |
  | Read current tags/labels | Required | getTags | GET ticket tags/labels |
  | Apply tags/labels | Required | applyTags | PUT/PATCH ticket tags |
  | Webhook signature verification | Recommended | parseWebhook | HMAC-SHA256 header or signing secret |
  ```

- [ ] **Step 3: Verify the edit**

  Read `skills/check-api/SKILL.md` and confirm:
  - The table now has 4 columns (Capability, Required?, SPI Method, Look for)
  - "Webhook push (inbound events)" is gone, "Webhook push — custom URL" is present
  - "Fetch ticket subject" row exists with `getSubject` in the SPI Method column
  - Row count is 7 (was 6)

- [ ] **Step 4: Commit**

  ```bash
  git add skills/check-api/SKILL.md
  git commit -m "feat(check-api): update ticket AI reply table to align with Ticket v2 SPI"
  ```

---

## Task 2: check-api — Add Feature 4 (Frontend Integration)

**Files:**
- Modify: `skills/check-api/SKILL.md`

- [ ] **Step 1: Add Feature 4 analysis section**

  After the Feature 3 (数据同步) table block and before `## Output Format`, insert the following new section.

  Find the old_string (end of Feature 3 block):
  ```
  | Rate limit documentation | Recommended | X-RateLimit headers or rate limit policy |

  ## Output Format
  ```

  Replace with:
  ```
  | Rate limit documentation | Recommended | X-RateLimit headers or rate limit policy |

  ### Feature 4: 前端集成评估 (Frontend Integration)

  Based on the authorization model and API capabilities already analyzed, derive the
  frontend Drawer spec. Do not re-query any docs — use what was found in Features 0–3.

  **AUTH SECTION** — determine from Feature 0 (Authorization Model):

  | Derive | From |
  |--------|------|
  | 授权方式 | Auth type: OAuth2 → "OAuth 跳转"; API Key → "API Key 填写"; 子域名 + OAuth → "子域名+OAuth" |
  | 输入字段 | Any inputs needed before the auth action (e.g. subdomain, account ID) |
  | 手工前置步骤 | MARKETPLACE_APP or CONDITIONAL steps the user must perform in the third-party admin console before they can authorize |

  **FEATURE SETTINGS SECTION** — one line per feasible feature:

  For each feature that is ✅ or ⚠️, describe what configuration options the frontend
  needs to expose. Common items:
  - 工单 AI 回复: agent identity selection, processing scope (all tickets vs. specific views/queues), tag configuration
  - Livechat: agent identity, channel/queue assignment, credential inputs if not covered by main auth
  - 数据同步: sync frequency, data range, field mapping options

  If a feature needs no frontend configuration beyond enabling it, write "无需额外配置".
  If a feature is ❌, write "N/A".

  **MANUAL GUIDANCE** — third-party platform operations the user must perform manually:
  - Always include: Webhook URL display (user must paste Shulex's webhook URL into the
    third-party platform's webhook settings page)
  - Add any other manual steps found during analysis (e.g. creating an OAuth app, enabling
    specific API scopes, configuring routing rules)
  - If no manual steps are needed beyond webhook URL: write only the webhook URL row

  ## Output Format
  ```

- [ ] **Step 2: Add Feature 4 block to CAPABILITY MATRIX output format**

  In the `## Output Format` section, find the SUMMARY block:
  ```
  SUMMARY
  ═══════════════════════════════════════════════════════════════
  授权模式:    {✅ SELF_AUTH / 🚨 MARKETPLACE_APP（需申请审核） / ⚠️ CONDITIONAL}
  工单 AI 回复:  {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
  Livechat 对接: {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
  数据同步:      {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
  ```

  Before the SUMMARY block, insert the FEATURE 4 output block. Find old_string:
  ```
  SUMMARY
  ═══════════════════════════════════════════════════════════════
  授权模式:    {✅ SELF_AUTH / 🚨 MARKETPLACE_APP（需申请审核） / ⚠️ CONDITIONAL}
  ```

  Replace with:
  ```
  FEATURE 4: 前端集成评估 (Frontend Integration)
  ─────────────────────────────────────────

  AUTH SECTION
  授权方式: {OAuth 跳转 / API Key 填写 / 子域名+OAuth / 多步骤}
  输入字段:
    - {字段名}: {用途} [必填/选填]
  手工前置步骤（三方平台操作，前端展示引导）:
    ⚠️ {步骤描述}       ← 仅当有手工步骤时，否则写 "— 无手工前置步骤"

  FEATURE SETTINGS SECTION
    - 工单 AI 回复: {可配置项，如 Agent 选择 / 处理范围 / 无需额外配置 / N/A}
    - Livechat:     {可配置项 或 N/A}
    - 数据同步:     {可配置项 或 N/A}

  MANUAL GUIDANCE（需在三方平台手工完成，前端展示操作引导）
    ⚠️ Webhook URL 配置: 前端展示 Shulex Webhook URL，提示用户在三方后台填入
    ⚠️ {其他手工步骤}
    — 无额外手工步骤    ← 仅 Webhook URL 一项时用此行替换其他 ⚠️ 行

  SUMMARY
  ═══════════════════════════════════════════════════════════════
  授权模式:    {✅ SELF_AUTH / 🚨 MARKETPLACE_APP（需申请审核） / ⚠️ CONDITIONAL}
  ```

- [ ] **Step 3: Add 前端集成 row to SUMMARY**

  Find the end of the SUMMARY block:
  ```
  数据同步:      {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
  {If MARKETPLACE_APP:}
  🚨 注意: 接入前需完成 Marketplace App 申请，建议尽早启动审核流程。
  ```

  Replace with:
  ```
  数据同步:      {✅ 全部支持 / ⚠️ 部分支持 / ❌ 无法支持}
  前端集成:      {简评，如 "OAuth 跳转授权 + 1 项手工 Webhook 配置" / "API Key 填写，无手工步骤"}
  {If MARKETPLACE_APP:}
  🚨 注意: 接入前需完成 Marketplace App 申请，建议尽早启动审核流程。
  ```

- [ ] **Step 4: Verify the edits**

  Read `skills/check-api/SKILL.md` and confirm:
  - "Feature 4: 前端集成评估" section exists in the analysis instructions (before Output Format)
  - CAPABILITY MATRIX output contains a "FEATURE 4" block between Feature 3 and SUMMARY
  - SUMMARY has a "前端集成" row after "数据同步"

- [ ] **Step 5: Commit**

  ```bash
  git add skills/check-api/SKILL.md
  git commit -m "feat(check-api): add Feature 4 frontend integration evaluation dimension"
  ```

---

## Task 3: flow-analyze — Add Frontend Aggregation Section

**Files:**
- Modify: `skills/flow-analyze/SKILL.md`

- [ ] **Step 1: Read the current file**

  Read `skills/flow-analyze/SKILL.md` to locate the Phase C → Report Generation boundary.

- [ ] **Step 2: Insert Phase D section**

  Find the transition from Phase C to Report Generation. The old_string to match:
  ```
  ## Report Generation

  Phase C 完成后，调用 `intelli:report` skill，传入：
  ```

  Replace with:
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
  手工前置步骤（三方平台操作，前端展示引导）:
    ⚠️ {步骤描述}    ← 仅当有手工步骤时；否则写 "— 无手工前置步骤"

  FEATURE SETTINGS SECTION
  {从"我方系统配置 Step"提取，每个功能点一行}
    - {功能名}: {可配置项说明}
    — 无需额外功能配置    ← 若无我方系统配置 Step

  MANUAL GUIDANCE（需在三方平台手工完成，前端展示操作引导）
    ⚠️ Webhook URL 配置: 前端展示 Shulex Webhook URL，提示用户在三方后台填入
    ⚠️ {其他三方后台操作 Step 的操作说明}
    — 无额外手工步骤    ← 仅 Webhook URL 一项时
  ```

  Pass this Frontend Integration section to `intelli:report` as additional context
  alongside the chain-mode flag.

  ## Report Generation

  Phase C 完成后，调用 `intelli:report` skill，传入：
  ```

- [ ] **Step 3: Add frontend context to the report call parameters**

  Find the existing report call parameters block:
  ```
  - Phase B 的完整验证结果
  - Phase C 的链路可行性总结
  - 当前用户角色（`pm` / `arch` / `dev` / `claude`）
  - 模式标识：`chain-mode`（让 report skill 使用链路模式模板）
  ```

  Replace with:
  ```
  - Phase B 的完整验证结果
  - Phase C 的链路可行性总结
  - Phase D 的前端集成评估（Frontend Integration section）
  - 当前用户角色（`pm` / `arch` / `dev` / `claude`）
  - 模式标识：`chain-mode`（让 report skill 使用链路模式模板）
  ```

- [ ] **Step 4: Verify the edits**

  Read `skills/flow-analyze/SKILL.md` and confirm:
  - "## Phase D: 前端集成评估" section exists between Phase C and Report Generation
  - The Report Generation parameters list includes "Phase D 的前端集成评估"

- [ ] **Step 5: Commit**

  ```bash
  git add skills/flow-analyze/SKILL.md
  git commit -m "feat(flow-analyze): add Phase D frontend integration aggregation after Phase C"
  ```

---

## Task 4: report — Add Frontend Section to pm.md Templates

**Files:**
- Modify: `skills/report/SKILL.md`

- [ ] **Step 1: Read the current file**

  Read `skills/report/SKILL.md` to locate the pm.md template sections (standard mode and chain mode).

- [ ] **Step 2: Add frontend section to standard pm.md template**

  In the standard `pm.md` template, find the closing fence before the next template separator. The old_string to match (end of pm.md template):
  ```
  ## 主要风险

  - {Risk 1, non-technical language}
  - {Risk 2}
  {≤3 items}
  ```
  ````
  ---

  ### `arch.md` — 产品 / 架构版
  ````

  Replace with:
  ```
  ## 主要风险

  - {Risk 1, non-technical language}
  - {Risk 2}
  {≤3 items}

  ## 前端集成页面

  授权完成后，集成 Drawer 大致如下：

  ```
  ┌─────────────────────────────────────────┐
  │  🔧 {Platform Name}                     │
  ├─────────────────────────────────────────┤
  │  ◉ 授权                                 │
  │  {If 子域名+OAuth:}                      │
  │    子域名: [____________________]       │
  │  {If API Key:}                          │
  │    API Key: [____________________]      │
  │    [连接 →]    ✓ 已授权 (已连接时)       │
  ├─────────────────────────────────────────┤
  │  ⚙ 功能设置                             │
  │  ┌──────────────────────────────────┐  │
  │  │ {每个可用功能一个 block，例如:}    │  │
  │  │ 工单 AI 回复                      │  │
  │  │   回复身份: [选择客服 ▼]          │  │
  │  │   处理范围: ○ 全部  ○ 指定视图    │  │
  │  └──────────────────────────────────┘  │
  ├─────────────────────────────────────────┤
  │  ⚠ 手工操作 (若有)                      │
  │  请在 {Platform} 后台配置 Webhook URL:  │
  │  https://intelli.shulex.com/v2/...      │
  │  [复制]                                 │
  └─────────────────────────────────────────┘
  ```

  需制作: {逗号分隔列表，从前端集成评估中推导，例如: 授权表单 / Agent 选择 / View 过滤列表 / Webhook URL 展示组件}
  ```
  ````
  ---

  ### `arch.md` — 产品 / 架构版
  ````

  Note: The ASCII mockup must be customized for the platform being analyzed. Replace
  auth inputs with the actual fields from the Frontend Integration AUTH SECTION. Replace
  feature settings block with actual feasible features. Remove the manual guidance row
  if there are no manual steps.

- [ ] **Step 3: Add frontend section to chain-mode pm.md template**

  Find the end of the chain-mode `pm.md` template:
  ```
  ## 研发主要工作
  - {需开发的 Step 任务}
  ```

  (followed by the chain-mode arch.md template block)

  After "研发主要工作" block and before the next template, add:
  ```
  ## 前端集成页面

  授权完成后，集成 Drawer 大致如下：

  ```
  ┌─────────────────────────────────────────┐
  │  🔧 {Platform Name}                     │
  ├─────────────────────────────────────────┤
  │  ◉ 授权                                 │
  │    {从 Phase D AUTH SECTION 推导输入字段} │
  │    [连接 →]    ✓ 已授权                  │
  ├─────────────────────────────────────────┤
  │  ⚙ 功能设置                             │
  │  ┌──────────────────────────────────┐  │
  │  │ {从 Phase D FEATURE SETTINGS 推导} │ │
  │  └──────────────────────────────────┘  │
  ├─────────────────────────────────────────┤
  │  ⚠ 手工操作 (若有)                      │
  │  {从 Phase D MANUAL GUIDANCE 推导}      │
  └─────────────────────────────────────────┘
  ```

  需制作: {从 Phase D 前端集成评估推导}
  ```

- [ ] **Step 4: Verify**

  Read `skills/report/SKILL.md` and confirm both pm.md templates (standard and chain-mode) now have a "前端集成页面" section with ASCII mockup.

- [ ] **Step 5: Commit**

  ```bash
  git add skills/report/SKILL.md
  git commit -m "feat(report): add frontend integration section to pm.md templates (ASCII mockup)"
  ```

---

## Task 5: report — Add Frontend Section to arch.md Templates

**Files:**
- Modify: `skills/report/SKILL.md`

- [ ] **Step 1: Add frontend section to standard arch.md template**

  Find the end of the standard arch.md template:
  ```
  ## 模块依赖关系

  {Implementation order constraints:}
  - {Module A} 必须先于 {Module B} 实现，原因：{one sentence}
  ```

  After the dependency section and before the next template separator, add:
  ```
  ## 前端集成

  **授权模式:** {从 check-api Feature 0 + Feature 4 AUTH SECTION 推导: OAuth2（收集子域名 → 跳转 → 回调写入 ExternKey）/ API Key（前端收集并存入 ExternKey.secretKey）/ 其他}

  **凭证流向:** {从前端输入字段 → 后端 ExternKey 存储的路径描述，一句话}

  **Drawer 结构:**
  - **Auth Section:** {输入字段说明 + 授权动作 + 已授权/已撤销状态描述}
  - **Feature Settings Section:** {各功能配置项说明，功能间独立}
  - **Manual Guidance:** {需展示的手工操作说明，如 Webhook URL 展示+复制；若无则写"无"}

  **手工步骤说明:** {Webhook URL 路径格式: `/v2/webhook/{PLATFORM_ID}/{token}`；其他需在三方后台完成的操作}
  ```

- [ ] **Step 2: Add frontend section to chain-mode arch.md template**

  Find the end of the chain-mode arch.md template:
  ```
  ## 依赖关系

  - {Step A} 必须先于 {Step B} 实施，原因：{one sentence}
  ```

  After the dependency section, add:
  ```
  ## 前端集成

  **授权模式:** {从 Phase D AUTH SECTION 推导}
  **凭证流向:** {输入字段 → ExternKey 存储路径}

  **Drawer 结构:**
  - **Auth Section:** {字段 + 动作 + 状态}
  - **Feature Settings Section:** {功能配置项}
  - **Manual Guidance:** {手工步骤或"无"}
  ```

- [ ] **Step 3: Verify**

  Read `skills/report/SKILL.md` and confirm both arch.md templates have "前端集成" section.

- [ ] **Step 4: Commit**

  ```bash
  git add skills/report/SKILL.md
  git commit -m "feat(report): add frontend integration section to arch.md templates"
  ```

---

## Task 6: report — Add Frontend Section to dev.md Templates

**Files:**
- Modify: `skills/report/SKILL.md`

- [ ] **Step 1: Add frontend section to standard dev.md template**

  Find the end of the standard dev.md template's Checklist section:
  ```
  ### 数据同步接入 Checklist
  {Only include this section if 数据同步 is ✅ or ⚠️}

  - [ ] 实现 `ISyncService` 订单同步（{if order sync feasible}）
    - [ ] 增量拉取参数: {param name}
    - [ ] 分页实现: {cursor / page+size}
  - [ ] 实现 `ISyncService` 商品同步（{if product sync feasible}）
  - [ ] 实现物流数据同步（{if logistics feasible}）
  - [ ] Rate limit 处理: {strategy}
  ```

  After the 数据同步 Checklist block, add:
  ```
  ### 前端集成开发说明
  {Always include this section}

  **Auth Section**

  | 字段 | 类型 | 必填 | 用途 |
  |------|------|------|------|
  | {字段名，从 Feature 4 AUTH SECTION 推导} | Input / Input.Password | ✅/— | {用途} |

  授权接口: `POST /integration/{platform}/auth` → 返回 `auth_url`，调用 `window.open(res.auth_url)` 跳转
  {If API Key only: "接口: `POST /integration/{platform}/auth` → 直接存储凭证，无跳转"}
  已授权状态: 表单折叠 + Revoke 按钮（`DELETE /integration/{platform}/auth`）

  **Feature Settings Section**

  {For each feasible feature, describe UI and API:}
  - **工单 AI 回复** (if feasible):
    - Agent 下拉: `GET /integration/{platform}/agents` → `[{id, name}]`
    - 处理范围: GLOBAL / SINGLE；SINGLE 时展开 View/Queue 多选列表 (`GET /integration/{platform}/views`)
    - 授权前 disabled mask 遮罩整个 Section
  - **Livechat** (if feasible):
    - {描述 Livechat 配置 UI，如 credential 输入、agent 选择}
  - **数据同步** (if feasible):
    - {描述同步范围选择等}

  **Manual Guidance Section** (if any manual steps)

  - Webhook URL: 从接口获取 (`GET /integration/{platform}/webhook-url`)，展示 + 一键复制
  - 提示文案: "请在 {Platform} 后台 → Webhooks 填入以下地址"
  - {其他手工步骤的 UI 说明}
  ```

- [ ] **Step 2: Add frontend section to chain-mode dev.md template**

  Find the end of the chain-mode dev.md template (after all Step N sections). Add:
  ```
  ## 前端集成开发说明
  {从 Phase D 前端集成评估生成，格式与标准模式相同}

  **Auth Section**

  | 字段 | 类型 | 必填 | 用途 |
  |------|------|------|------|
  | {从 Phase D AUTH SECTION 推导} | | | |

  授权接口: `POST /integration/{platform}/auth`

  **Feature Settings Section**

  {从 Phase D FEATURE SETTINGS SECTION 推导，每功能一条}

  **Manual Guidance Section**

  {从 Phase D MANUAL GUIDANCE 推导}
  ```

- [ ] **Step 3: Verify**

  Read `skills/report/SKILL.md` and confirm both dev.md templates have "前端集成开发说明" section.

- [ ] **Step 4: Commit**

  ```bash
  git add skills/report/SKILL.md
  git commit -m "feat(report): add frontend integration section to dev.md templates"
  ```

---

## Task 7: report — Add Frontend Section to spec.md Templates

**Files:**
- Modify: `skills/report/SKILL.md`

- [ ] **Step 1: Add frontend section to standard spec.md template**

  Find the end of the standard spec.md template:
  ```
  ## 依赖

  - 第三方 API 文档: {URL}
  - 需要的凭据/权限: {list}
  {Only include if authorization model is MARKETPLACE_APP or CONDITIONAL:}
  - 🚨 前置条件: 需完成 Marketplace App 申请，申请入口: {URL}
  ```

  After the 依赖 section, add:
  ```
  ## 前端集成规格

  ### Auth Section

  **授权方式:** {OAuth2 跳转 / API Key 直存 / 子域名+OAuth}

  **输入字段:**

  | 字段名 | 类型 | 必填 | 校验规则 | placeholder |
  |--------|------|------|---------|-------------|
  | {字段} | Input / Input.Password / Select | true/false | {规则，如 required / 正则} | {提示文字} |

  **状态机:**
  - `unauthenticated`: 表单展开，Revoke 按钮隐藏
  - `authenticating`: 提交按钮 loading，字段 disabled
  - `authenticated`: 表单折叠，显示 "✓ 已授权" + Revoke 按钮
  - `revoking`: Revoke 确认弹窗 → 成功后回到 `unauthenticated`

  **接口:**
  - 发起授权: `POST /integration/{platform}/auth` · body: `{ {字段名}: string, ... }` · response: `{ auth_url: string }` (OAuth) or `{ success: boolean }` (API Key)
  - 撤销授权: `DELETE /integration/{platform}/auth` · body: `{ appId: number }`

  **错误处理:**
  - 字段为空提交: 表单 inline 校验，阻止提交
  - auth_url 请求失败: `message.error('授权失败，请重试')`
  - Revoke 失败: `message.error` + 关闭 loading，不关闭弹窗

  ### Feature Settings Section

  {For each feasible feature, one subsection:}

  #### 工单 AI 回复 (if feasible)

  **授权前状态:** disabled mask 遮罩整个 Section

  **Agent 选择:**
  - 组件: Collapse 展开 + 滚动列表
  - 接口: `GET /integration/{platform}/agents` · response: `[{ id: number, name: string, email: string }]`
  - 必选，未选时保存阻断并提示错误

  **处理范围:**
  - 组件: Select（GLOBAL / SINGLE）
  - SINGLE 时展开 View/Queue 多选列表
  - 接口: `GET /integration/{platform}/views` · response: `[{ id: number, name: string }]`
  - GLOBAL 时 Collapse 折叠并 disabled

  **保存接口:** `POST /integration/{platform}/settings` · body: `{ agentId, rule: { scope, views? } }`

  #### Livechat (if feasible)

  {类似结构，列出 Livechat 配置字段、接口、校验规则}

  #### 数据同步 (if feasible)

  {类似结构，列出同步配置字段、接口、校验规则}

  ### Manual Guidance Section (if any manual steps)

  **Webhook URL 展示:**
  - 接口: `GET /integration/{platform}/webhook-url` · response: `{ url: string }`
  - 组件: 只读 Input + "复制" 按钮（`navigator.clipboard.writeText`）
  - 提示文案: "请前往 {Platform} 管理后台 → Webhooks → 新建，填入以下 URL"

  {其他手工步骤的组件和文案规格}
  ```

- [ ] **Step 2: Add frontend section to chain-mode spec.md template**

  Find the end of the chain-mode spec.md template:
  ```
  ## 依赖与前置条件

  - {External API docs, credentials, Marketplace App approval if needed}
  ```

  After the 依赖 section, add:
  ```
  ## 前端集成规格

  {从 Phase D 前端集成评估生成，格式与标准模式 spec.md 前端规格相同}

  ### Auth Section
  {字段表格、状态机、接口、错误处理}

  ### Feature Settings Section
  {每个涉及我方配置的 Step 对应一个子 section}

  ### Manual Guidance Section
  {三方后台操作 Step 对应的 UI 展示规格}
  ```

- [ ] **Step 3: Verify**

  Read `skills/report/SKILL.md` and confirm both spec.md templates have "前端集成规格" section with field tables, state machine, and API signatures.

- [ ] **Step 4: Final check: count frontend sections across all templates**

  Grep for "前端集成" in `skills/report/SKILL.md`:
  ```bash
  grep -n "前端集成" skills/report/SKILL.md
  ```
  Expected: 8 matches (pm.md × 2, arch.md × 2, dev.md × 2, spec.md × 2).

- [ ] **Step 5: Commit**

  ```bash
  git add skills/report/SKILL.md
  git commit -m "feat(report): add frontend integration section to spec.md templates (full UI spec)"
  ```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|-----------------|------------|
| 工单 AI 回复 table aligned to Ticket v2 SPI | Task 1 |
| "Webhook push" → custom URL semantics | Task 1 |
| "Fetch ticket subject" new row | Task 1 |
| SPI Method column | Task 1 |
| Feature 4 analysis instructions in check-api | Task 2 Step 1 |
| Feature 4 output block in CAPABILITY MATRIX | Task 2 Step 2 |
| 前端集成 row in SUMMARY | Task 2 Step 3 |
| flow-analyze Phase D aggregation section | Task 3 Step 2 |
| Phase D passed to intelli:report | Task 3 Step 3 |
| pm.md: ASCII mockup (standard mode) | Task 4 Step 2 |
| pm.md: ASCII mockup (chain mode) | Task 4 Step 3 |
| arch.md: auth mechanism + section responsibilities (standard) | Task 5 Step 1 |
| arch.md: auth mechanism + section responsibilities (chain) | Task 5 Step 2 |
| dev.md: fields + API calls + state transitions (standard) | Task 6 Step 1 |
| dev.md: fields + API calls + state transitions (chain) | Task 6 Step 2 |
| spec.md: full UI spec ready for development (standard) | Task 7 Step 1 |
| spec.md: full UI spec ready for development (chain) | Task 7 Step 2 |
| Role depth increases pm → arch → dev → spec | Tasks 4–7 by design |

**Placeholder scan:** No TBD/TODO. All template placeholders use `{...}` syntax which is correct for skill templates (they are instructions to Claude, not hardcoded values).

**Type consistency:** AUTH SECTION / FEATURE SETTINGS SECTION / MANUAL GUIDANCE structure is used identically across check-api Feature 4, flow-analyze Phase D, and all report templates.
