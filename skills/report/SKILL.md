---
name: report
description: Generates four role-specific feasibility report documents from the architecture mapping. Always produces pm.md, arch.md, dev.md, and spec.md in a subdirectory. Displays only the document matching the current user role.
---

# intelli:report — Role-Aware Feasibility Report Generator

## Purpose

Generate four role-specific feasibility documents from the architecture mapping.
Save all four to a subdirectory under `docs/platform-analysis/`. In the conversation,
display only the document matching the current user's role, and list paths to the others.

This is Phase 5 of the full analysis flow. Can also be used standalone.

## Input

Either:
- Architecture mapping output from `intelli:map-arch` + role identifier (if called from `intelli:analyze`)
- User-provided summary of platform capabilities and gaps + role (if used standalone)

**Role identifier** (`pm` / `arch` / `dev` / `claude`):
- If received from `intelli:analyze` context: use it directly, do not ask again
- If called standalone with no role in context: ask once before generating:
  ```
  你是哪类受众？
  1. PM / 交付
  2. 产品 / 架构
  3. 研发
  4. Claude（AI 开发，生成 writing-plans 输入）
  ```

## Output Directory

Create the directory if it doesn't exist, then save four files:

```
docs/platform-analysis/YYYY-MM-DD-{platform-name}/
  pm.md
  arch.md
  dev.md
  spec.md
```

Platform name: lowercase, hyphen-separated (e.g. `zoom-contact-center`).

## Document Templates

Generate all four documents. Fill every section with real analysis — no placeholders.

---

### `pm.md` — PM / 交付版

````markdown
# {Platform Name} 接入可行性评估 — PM / 交付版

> 分析日期: {YYYY-MM-DD}
> 分析人: Claude (intelli:analyze)
> 数据来源: {URL / file / description}

---

{Only include if authorization model is MARKETPLACE_APP or CONDITIONAL:}
## ⚠️ 授权前置条件

> 🚨 **本平台需通过官方 Marketplace App 审核才能对客户进行授权。**
>
> - **申请流程**: {描述申请步骤}
> - **预计审核周期**: {X 周 / 不确定}
> - **受限能力**: {审核前无法访问的 API 列表}
> - **建议**: 在启动研发前，先行提交申请，避免研发完成后因审核延误上线。

---

## 结论

| 功能 | 结论 | 说明 |
|------|------|------|
| 授权模式 | {✅ 客户自助授权 / 🚨 需申请审核 / ⚠️ 部分受限} | {one sentence} |
| 工单AI回复 | {✅/⚠️/❌} {可行/部分可行/不可行} | {one sentence} |
| Livechat对接 | {✅/⚠️/❌} {可行/部分可行/不可行} | {one sentence} |
| 数据同步 | {✅/⚠️/❌} {可行/部分可行/不可行} | {one sentence} |

## 建议

{2–3 sentences: which features to implement, which to skip, sequencing recommendation. No technical terms.}

## 工作量汇总

> 数据来源于研发版差距分析的工作量评估，此处汇总为非技术语言。

| 功能模块 | 预计周期 |
|---------|---------|
| {module} | {X 天 / X 周} |
| **合计** | **{total}** |

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

需制作: {逗号分隔列表，从前端集成评估推导，例如: 授权表单 / Agent 选择 / View 过滤列表 / Webhook URL 展示组件}

> 根据平台实际情况调整：替换授权输入字段、功能设置 block、手工操作说明；若无手工步骤则移除底部分区。
````

---

### `arch.md` — 产品 / 架构版

```markdown
# {Platform Name} 接入可行性评估 — 产品 / 架构版

> 分析日期: {YYYY-MM-DD}
> 分析人: Claude (intelli:analyze)
> 数据来源: {URL / file / description}

---

## 系统边界

| 系统 | 职责 |
|------|------|
| {第三方平台} | {事件来源、数据提供方、配置入口} |
| Intelli | {接收、路由、工单/会话处理} |
| shulex_gpt | {AI 能力：ASR/TTS/NLU/Tool Call（如适用）} |

## 数据流

{描述事件/消息如何在三方间流转，每条一步骤：}

1. {第三方平台} → Intelli: {触发事件或 API 调用，如 webhook `engagement.created`}
2. Intelli → shulex_gpt: {AI 处理请求，如生成回复 / ASR / 意图识别}
3. shulex_gpt → Intelli: {返回 AI 结果}
4. Intelli → {第三方平台}: {出站操作，如发送回复 / 更新工单}

## 关键架构决策

{For each feasible feature dimension, one decision point:}

**工单AI回复:** {直接套用现有 TicketEngine V2 SPI / 需新增适配层 — 原因}
**Livechat对接:** {复用现有 Webhook 接收链路 / 需新 WebSocket 链路 — 原因}
**数据同步:** {标准 ISyncService 实现 / 需定制轮询策略 — 原因}

## 技术前置条件

{List external dependencies that must be confirmed before development:}
- {Condition 1: e.g., 申请 Marketplace App 审核（预计 X 周）}
- {Condition 2: e.g., 获取测试账户 + Webhook 回调域名}

## 模块依赖关系

{Implementation order constraints:}
- {Module A} 必须先于 {Module B} 实现，原因：{one sentence}

## 前端集成

**授权模式:** {从 check-api Feature 0 + Feature 4 AUTH SECTION 推导: 如 "OAuth2（收集子域名 → 跳转 → 回调写入 ExternKey）" / "API Key（前端收集并存入 ExternKey.secretKey）"}

**凭证流向:** {从前端输入字段 → 后端 ExternKey 存储的路径，一句话}

**Drawer 结构:**
- **Auth Section:** {输入字段说明 + 授权动作 + 已授权/已撤销状态描述}
- **Feature Settings Section:** {各功能配置项说明，功能间独立}
- **Manual Guidance:** {需展示的手工操作，如 Webhook URL 展示+复制；若无则写"无"}

**Webhook URL 路径格式（若适用）:** `/v2/webhook/{PLATFORM_ID}/{token}`
```

---

### `dev.md` — 研发版

```markdown
# {Platform Name} 接入可行性评估 — 研发版

> 分析日期: {YYYY-MM-DD}
> 分析人: Claude (intelli:analyze)
> 数据来源: {URL / file / description}

---

## 授权与接入模式

**授权类型：** {API Key / OAuth2 / JWT / Basic Auth}
**授权模式：** {✅ 客户自助授权 / 🚨 需 Marketplace App 审核 / ⚠️ 部分受限}

{Only include if authorization model is MARKETPLACE_APP or CONDITIONAL:}
**申请要求：**
- 申请入口: {URL}
- 申请材料: {描述}
- 审核周期: {预估}
- 受限 API: {列表}

---

## 工单AI回复

**可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

**差距列表：**
- [{Minor/Medium/Blocking}] {gap description} → {recommended workaround or "no workaround"}

**预估工作量：** {小（3–5天）/ 中（1–2周）/ 大（2–4周）/ 不建议实现}

---

## Livechat对接

**可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

**差距列表：**
- [{Minor/Medium/Blocking}] {gap description} → {workaround or "no workaround"}

**预估工作量：** {小 / 中 / 大 / 不建议}

---

## 数据同步

**可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

**差距列表：**
- [{Minor/Medium/Blocking}] {gap description} → {workaround or "no workaround"}

**预估工作量：** {小 / 中 / 大 / 不建议}

---

## 接入 Checklist

> 仅列出可行或部分可行的功能。

### 工单AI回复接入 Checklist
{Only include this section if 工单AI回复 is ✅ or ⚠️}

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
{Only include this section if Livechat对接 is ✅ or ⚠️}

- [ ] 实现 Livechat 消息接收通道（{WebSocket / Webhook / Polling}）
- [ ] 实现 outbound 消息发送 — 接口: {endpoint}
- [ ] 实现 session 生命周期处理（{note workarounds if needed}）
- [ ] 消息幂等 key: {field name}
- [ ] 接入 Kafka 消息管道

### 数据同步接入 Checklist
{Only include this section if 数据同步 is ✅ or ⚠️}

- [ ] 实现 `ISyncService` 订单同步（{if order sync feasible}）
  - [ ] 增量拉取参数: {param name}
  - [ ] 分页实现: {cursor / page+size}
- [ ] 实现 `ISyncService` 商品同步（{if product sync feasible}）
- [ ] 实现物流数据同步（{if logistics feasible}）
- [ ] Rate limit 处理: {strategy}

### 前端集成开发说明

**Auth Section**

| 字段 | 类型 | 必填 | 用途 |
|------|------|------|------|
| {字段名，从 Feature 4 AUTH SECTION 推导} | Input / Input.Password | ✅/— | {用途} |

授权接口: `POST /integration/{platform}/auth`
- OAuth: 返回 `{ auth_url: string }`，调用 `window.open(auth_url)` 跳转
- API Key: 返回 `{ success: boolean }`，无跳转

已授权状态: 表单折叠 + Revoke 按钮（`DELETE /integration/{platform}/auth`）

**Feature Settings Section**

- **工单 AI 回复** (if feasible):
  - Agent 下拉: `GET /integration/{platform}/agents` → `[{id, name}]`
  - 处理范围 GLOBAL/SINGLE；SINGLE 时展开 View/Queue 多选列表 (`GET /integration/{platform}/views`)
  - 授权前 disabled mask 遮罩整个 Section
- **Livechat** (if feasible): {描述 Livechat 配置 UI，如 credential 输入字段}
- **数据同步** (if feasible): {描述同步范围选择等}

**Manual Guidance Section** (if any manual steps)

- Webhook URL: 从接口获取 (`GET /integration/{platform}/webhook-url`)，展示 + 一键复制
- 提示文案: "请在 {Platform} 后台 → Webhooks 填入以下地址"
```

---

### `spec.md` — Claude Spec（writing-plans 输入）

```markdown
# {Platform Name} 接入需求规格 — Claude Spec

> 分析日期: {YYYY-MM-DD}
> 用途: 供 superpowers:writing-plans 生成实现计划
> 数据来源: {URL / file / description}

---

## 目标

{One sentence: what integration to build and which features to implement.}

## 范围

**包含：**
- {Feasible feature 1}
- {Feasible feature 2}

**不包含：**
- {❌ infeasible feature — reason}

## 现有接口约束

需实现以下 Intelli SPI 接口（代码位于 shulex_intelli 仓库）：

- **工单AI回复**: `TicketPlatformPlugin` + `TicketOperations`（package: `com.shulex.intelli.ticket.v2.spi`）
- **Livechat**: `LivechatSessionManager` + outbound sender（参考现有实现）
- **数据同步**: `ISyncService`（参考现有 Shopify / Amazon 实现）

{Remove lines for infeasible features.}

## 差距列表（仅可行项）

| 差距 | 严重程度 | Workaround |
|------|---------|-----------|
| {gap description} | Minor/Medium/Blocking | {workaround or "需新开发"} |

## 验收标准

{For each feasible feature (✅ or ⚠️), include the corresponding line:}
- **工单AI回复**: Webhook 能解析并创建工单；`sendReply()` 能成功发送回复；签名验证通过
- **Livechat对接**: 消息能实时接收并路由到 AI；outbound 消息能送达；session 生命周期正确维护
- **数据同步**: 增量同步无漏单；分页正确处理；rate limit 不触发 429

## 依赖

- 第三方 API 文档: {URL}
- 需要的凭据/权限: {list}
{Only include if authorization model is MARKETPLACE_APP or CONDITIONAL:}
- 🚨 前置条件: 需完成 Marketplace App 申请，申请入口: {URL}
```

---

## Conversation Display Rules

After generating and saving all four files:

1. **完整展示**当前角色对应的文档内容（粘贴全文到对话）
2. 输出其余三份路径：

```
其他报告：
- {未展示角色1}: docs/platform-analysis/YYYY-MM-DD-{platform}/xx.md
- {未展示角色2}: docs/platform-analysis/YYYY-MM-DD-{platform}/xx.md
- {未展示角色3}: docs/platform-analysis/YYYY-MM-DD-{platform}/xx.md
```

Role → file mapping:
- `pm` → `pm.md`（完整展示）
- `arch` → `arch.md`（完整展示）
- `dev` → `dev.md`（完整展示）
- `claude` → `spec.md`（完整展示）

最后宣告：`报告已保存至 docs/platform-analysis/YYYY-MM-DD-{platform}/`

---

## Chain Mode Report（链路模式）

当被 `intelli:flow-analyze` 调用时，生成链路模式四份报告。

保存至：`docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}/`

各文档使用以下模板：

**`pm.md`（链路模式）**：

````markdown
# {业务目标} 链路可行性报告 — PM / 交付版

> 分析日期: {YYYY-MM-DD}
> 涉及平台: {平台列表}

{If any step requires MARKETPLACE_APP approval:}
## ⚠️ 授权前置条件
> 🚨 需完成 Marketplace App 申请后方可实施，详见研发版 arch.md。

## 链路总览

| Step | 描述 | 平台/系统 | 结论 | 关键说明 |
|------|------|----------|------|---------|
| {N} | {描述} | {平台} | ✅/⚠️/❌ | {一句话} |

**整体结论：** {可行 / 部分可行（N个前置条件，N项待开发）/ 存在阻断}

## 主要前置条件
- {🚨 申请审核项置顶}
- {其他前置条件}

## 研发主要工作
- {需开发的 Step 任务}

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
````

**`arch.md`（链路模式）**：

```markdown
# {业务目标} 链路可行性报告 — 产品 / 架构版

> 分析日期: {YYYY-MM-DD}
> 涉及平台: {平台列表}

## 业务链路全貌

| Step | 系统 | 动作 | 依赖 |
|------|------|------|------|
| {N} | {系统} | {动作} | {依赖或"无"} |

## 跨平台数据流

{描述事件如何跨多个平台流转，每条一行}

## 关键技术决策

{For each "需开发" Step:}
**Step N — {步骤名}**: {方案选择及原因}

## 技术前置条件

- {Condition 1}
- {Condition 2}

## 依赖关系

- {Step A} 必须先于 {Step B} 实施，原因：{one sentence}

## 前端集成

**授权模式:** {从 Phase D AUTH SECTION 推导}
**凭证流向:** {输入字段 → ExternKey 存储路径}

**Drawer 结构:**
- **Auth Section:** {字段 + 动作 + 状态}
- **Feature Settings Section:** {功能配置项，来自 Phase D FEATURE SETTINGS}
- **Manual Guidance:** {来自 Phase D MANUAL GUIDANCE，或"无"}
```

**`dev.md`（链路模式）**：

```markdown
# {业务目标} 链路可行性报告 — 研发版

> 分析日期: {YYYY-MM-DD}
> 涉及平台: {平台列表}

{For each Step (✅/⚠️/❌), paste the full verification output from Phase B:}

## Step {N}: {步骤名称}

**结论：** {✅/⚠️/❌} {可行 / 有条件 / 需开发 / 阻断}

**API / 配置：**
| 操作 | 类型 | 端点 / 入口 | 文档链接 |
|------|------|------------|---------|
| {操作} | {类型} | {端点} | [{标题}]({URL}) |

**我方能力（knowledge-base）：**
| 能力 | 状态 | 备注 |
|------|------|------|
| {能力} | ✅/⚠️/❌ | {备注} |

{If ⚠️ 有条件:}
**有条件说明：** {限制描述}
**参考资料：** [{资料名}]({URL})

{If ⚠️ 需开发:}
**需开发说明：** {模块和工作量}
**参考资料：** [{资料名}]({URL})

{If ❌ 阻断:}
**阻断原因：** {技术限制说明，引用文档证据}

## 前端集成开发说明

（从 Phase D 前端集成评估生成）

**Auth Section**

| 字段 | 类型 | 必填 | 用途 |
|------|------|------|------|
| {从 Phase D AUTH SECTION 推导} | | | |

授权接口: `POST /integration/{platform}/auth`
已授权状态: 表单折叠 + Revoke 按钮（`DELETE /integration/{platform}/auth`）

**Feature Settings Section**

{从 Phase D FEATURE SETTINGS SECTION 推导，每功能一条}

**Manual Guidance Section**

{从 Phase D MANUAL GUIDANCE 推导；若"— 无手工步骤"则省略本小节}
```

**`spec.md`（链路模式）**：

```markdown
# {业务目标} 链路实现需求规格 — Claude Spec

> 分析日期: {YYYY-MM-DD}
> 用途: 供 superpowers:writing-plans 生成实现计划

## 目标

{One sentence: what business flow to implement and which platforms are involved.}

## 范围

**包含（✅/⚠️ Step）：**
- Step {N}: {描述}

**不包含（❌ 阻断）：**
- Step {N}: {描述} — 原因: {技术限制}

## 各 Step 实现需求

{For each ✅/⚠️ Step:}
### Step {N}: {步骤名}

**需实现：** {具体开发任务}
**依赖接口/API：** {endpoint or SPI interface}
**参考资料：** {URL}

## 验收标准

{For each ✅/⚠️ Step:}
- **Step {N}**: {completion definition}

## 依赖与前置条件

- {External API docs, credentials, Marketplace App approval if needed}
```

对话展示规则与标准模式相同（角色对应文档完整展示，其余给路径）。

---

## Standalone vs Orchestrated

- **Standalone** (`/intelli:report`): 收集角色（若无）→ 生成四份文档 → 按规则展示 → 停止。
- **Orchestrated**（来自 `intelli:analyze`）: 接收角色参数 → 生成四份文档 → 按规则展示 → 返回控制权给 orchestrator。
