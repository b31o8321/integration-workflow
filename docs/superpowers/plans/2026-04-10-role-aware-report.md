# Role-Aware Report System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 intelli 插件的报告系统改造为角色感知模式——分析开始时识别用户身份，对话按角色定制，每次分析固定生成四份目标文档（pm/arch/dev/spec），对话中仅完整展示当前角色对应的那份。

**Architecture:** 角色在 `intelli:analyze` / `intelli:flow-analyze` 入口问题中收集，贯穿整个分析对话，最终传入 `intelli:report`。report 技能负责生成四份独立文件到子目录，并按角色控制对话输出。

**Tech Stack:** Markdown skill files (SKILL.md)，无需编译或测试框架。验证方式为手动检查输出格式和文件生成结果。

---

### Task 1: 重写 `skills/report/SKILL.md`

这是改动最核心的部分。新版支持角色参数，生成四个文件到子目录，并按角色控制对话展示。

**Files:**
- Modify: `skills/report/SKILL.md`

- [ ] **Step 1: 读取现有文件，记录当前内容**

  运行：确认文件路径 `skills/report/SKILL.md`，全文读取，留意现有的 Report Structure、Save Location、Chain Mode 三个主要块。

- [ ] **Step 2: 用以下完整内容替换 `skills/report/SKILL.md`**

  将文件内容完全替换为：

  ```markdown
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

  ```markdown
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

  | 功能模块 | 预计周期 |
  |---------|---------|
  | {module} | {X 天 / X 周} |
  | **合计** | **{total}** |

  ## 主要风险

  - {Risk 1, non-technical language}
  - {Risk 2}
  {≤3 items}
  ```

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

  {描述事件/消息如何在三方间流转，每条一步骤，箭头格式：}

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

  {If MARKETPLACE_APP or CONDITIONAL:}
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
  {same format}

  **预估工作量：** {same format}

  ---

  ## 数据同步

  **可行性：** {✅ 可行 / ⚠️ 部分可行 / ❌ 不可行}

  **差距列表：**
  {same format}

  **预估工作量：** {same format}

  ---

  ## 接入 Checklist

  > 仅列出可行或部分可行的功能。

  ### 工单AI回复接入 Checklist
  {Only if ✅ or ⚠️}

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
  {Only if ✅ or ⚠️}

  - [ ] 实现 Livechat 消息接收通道（{WebSocket / Webhook / Polling}）
  - [ ] 实现 outbound 消息发送 — 接口: {endpoint}
  - [ ] 实现 session 生命周期处理（{note workarounds if needed}）
  - [ ] 消息幂等 key: {field name}
  - [ ] 接入 Kafka 消息管道

  ### 数据同步接入 Checklist
  {Only if ✅ or ⚠️}

  - [ ] 实现 `ISyncService` 订单同步（{if order sync feasible}）
    - [ ] 增量拉取参数: {param name}
    - [ ] 分页实现: {cursor / page+size}
  - [ ] 实现 `ISyncService` 商品同步（{if product sync feasible}）
  - [ ] 实现物流数据同步（{if logistics feasible}）
  - [ ] Rate limit 处理: {strategy}
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

  {One sentence: what integration to build and which features to implement.
   Example: "将 Freshdesk 接入 Shulex Intelli，实现工单 AI 自动回复和历史工单数据同步。"}

  ## 范围

  **包含：**
  - {Feasible feature 1}
  - {Feasible feature 2}

  **不包含：**
  - {❌ infeasible feature and reason}

  ## 现有接口约束

  需实现以下 Intelli SPI 接口（代码位于 shulex_intelli 仓库）：

  {For each feasible feature:}
  - **工单AI回复**: `TicketPlatformPlugin` + `TicketOperations`（package: `com.shulex.intelli.ticket.v2.spi`）
  - **Livechat**: `LivechatSessionManager` + outbound sender（参考现有实现）
  - **数据同步**: `ISyncService`（参考现有 Shopify / Amazon 实现）

  ## 差距列表（仅可行项）

  {Only list ✅ or ⚠️ gaps — omit ❌ features entirely}

  | 差距 | 严重程度 | Workaround |
  |------|---------|-----------|
  | {gap description} | Minor/Medium/Blocking | {workaround or "需新开发"} |

  ## 验收标准

  {Per feasible feature:}
  - **工单AI回复**: Webhook 能解析并创建工单；`sendReply()` 能成功发送回复；签名验证通过
  - **Livechat对接**: 消息能实时接收并路由到 AI；outbound 消息能送达；session 生命周期正确维护
  - **数据同步**: 增量同步无漏单；分页正确处理；rate limit 不触发 429

  ## 依赖

  - 第三方 API 文档: {URL}
  - 需要的凭据/权限: {list}
  {If MARKETPLACE_APP:}
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

  各文档内容调整：

  **`pm.md`（链路模式）**：
  - Step 汇总表（编号/描述/平台/结论/关键说明）
  - 整体结论
  - 主要前置条件列表
  - 研发主要工作列表

  **`arch.md`（链路模式）**：
  - 业务链路全貌（Step 序列 + 系统边界）
  - 跨平台数据流
  - 关键技术决策（每个需开发 Step 的方案选择）
  - 前置条件 + 依赖关系

  **`dev.md`（链路模式）**：
  - 每个 Step 的完整验证结果
  - API / 配置表格，每行附文档链接
  - 我方能力对照
  - 有条件/需开发/阻断的详细说明

  **`spec.md`（链路模式）**：
  - 目标：业务链路一句话描述
  - 范围：仅包含 ✅/⚠️ 的 Step
  - 每个需开发 Step 的实现需求
  - 验收标准：每 Step 的完成定义

  对话展示规则与标准模式相同（角色对应文档完整展示，其余给路径）。

  ---

  ## Standalone vs Orchestrated

  - **Standalone** (`/intelli:report`): 收集角色（若无）→ 生成四份文档 → 按规则展示 → 停止。
  - **Orchestrated**（来自 `intelli:analyze`）: 接收角色参数 → 生成四份文档 → 按规则展示 → 返回控制权给 orchestrator。
  ```

- [ ] **Step 3: 确认文件已写入，格式正确**

  读取 `skills/report/SKILL.md`，确认：
  - frontmatter description 已更新
  - 四个文档模板均存在（pm/arch/dev/spec）
  - Conversation Display Rules 章节存在
  - Chain Mode 章节已更新为四份文档

- [ ] **Step 4: Commit**

  ```bash
  git add skills/report/SKILL.md
  git commit -m "feat: rewrite report skill with role-aware 4-doc generation"
  ```

---

### Task 2: 更新 `skills/analyze/SKILL.md`

在 Phase 1 的最开头加入角色识别问题，并在 Phase 5 调用 report 时传递角色。

**Files:**
- Modify: `skills/analyze/SKILL.md`

- [ ] **Step 1: 在 Phase 1 开头插入角色识别问题**

  在 `### Phase 1: 业务场景收集` 下、三个业务问题之前，插入：

  ```markdown
  **首先，请确认你的角色**（影响整个分析过程的对话深度和报告展示）：

  ```
  你是哪类受众？
  1. PM / 交付 — 关注结论、工作量、风险
  2. 产品 / 架构 — 关注系统边界、数据流、架构决策
  3. 研发 — 需要 API 细节、差距分析、接入 Checklist
  4. Claude（AI 开发）— 生成 writing-plans 输入的需求规格
  ```

  记录角色标识：`pm` / `arch` / `dev` / `claude`。

  角色确定后，后续对话按以下方式调整：
  - `pm`：用业务语言，不展示 API 细节，中间结果只给结论
  - `arch`：适量技术深度，强调边界和决策点
  - `dev`：完整技术细节，主动展示 API 端点和差距
  - `claude`：结构化输出，避免叙述性文字，以结构化列表和表格为主
  ```

- [ ] **Step 2: 更新 Phase 5 中调用 report 的指令**

  找到 `### Phase 5: Report Generation` 下的：
  ```
  Invoke the `intelli:report` skill with the architecture mapping from Phase 3.
  ```

  替换为：
  ```
  Invoke the `intelli:report` skill with:
  - The architecture mapping from Phase 3
  - The role identifier collected in Phase 1 (pass as context: "当前用户角色: {role}")
  ```

- [ ] **Step 3: 确认修改正确**

  读取 `skills/analyze/SKILL.md`，确认：
  - Phase 1 开头有角色识别问题（四选一）
  - 有角色对应的对话风格说明（pm/arch/dev/claude 各一条）
  - Phase 5 中 report 调用附带了角色传递

- [ ] **Step 4: Commit**

  ```bash
  git add skills/analyze/SKILL.md
  git commit -m "feat: add role detection to analyze Phase 1"
  ```

---

### Task 3: 更新 `skills/flow-analyze/SKILL.md`

在独立调用入口加入角色识别，更新 Report Generation 章节为四份文档输出。

**Files:**
- Modify: `skills/flow-analyze/SKILL.md`

- [ ] **Step 1: 在 Input 章节末尾添加角色收集逻辑**

  找到 `## Input` 章节末尾（`若直接调用（/intelli:flow-analyze），先收集以上信息。` 这行之后），插入：

  ```markdown
  **角色识别：**
  - 若来自 `intelli:analyze`（已有角色上下文）：直接使用，不再询问
  - 若直接调用：在收集业务背景后，询问角色：
    ```
    你是哪类受众？
    1. PM / 交付
    2. 产品 / 架构
    3. 研发
    4. Claude（AI 开发）
    ```
    记录角色标识：`pm` / `arch` / `dev` / `claude`
  ```

- [ ] **Step 2: 替换 Report Generation 章节**

  找到 `## Report Generation` 整个章节，替换为：

  ```markdown
  ## Report Generation

  Phase C 完成后，调用 `intelli:report` skill，传入：
  - Phase B 的完整验证结果
  - Phase C 的链路可行性总结
  - 当前用户角色（`pm` / `arch` / `dev` / `claude`）
  - 模式标识：`chain-mode`（让 report skill 使用链路模式模板）

  report skill 将生成四份文档到：
  ```
  docs/platform-analysis/YYYY-MM-DD-{业务目标-slugified}/
    pm.md / arch.md / dev.md / spec.md
  ```

  并按角色展示规则输出对话内容（完整展示当前角色文档 + 其余三份路径）。
  ```

- [ ] **Step 3: 确认修改正确**

  读取 `skills/flow-analyze/SKILL.md`，确认：
  - Input 章节有角色识别逻辑（区分来自 analyze vs 直接调用）
  - Report Generation 章节改为调用 `intelli:report`，不再内嵌报告模板
  - 传递了角色和 `chain-mode` 标识

- [ ] **Step 4: Commit**

  ```bash
  git add skills/flow-analyze/SKILL.md
  git commit -m "feat: add role detection and delegate report to intelli:report in flow-analyze"
  ```

---

### Task 4: 更新 `README.md`

同步文档：角色表格、报告路径、skill 描述。

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 替换"各角色适用场景"表格**

  找到：
  ```markdown
  ## 各角色适用场景

  | 角色 | 推荐用法 | 获得产出 |
  |------|---------|---------|
  | PM / 交付 | `/intelli:analyze` 在 Phase 2 停止 | 能力矩阵，快速判断可行性 |
  | 技术负责人 | `/intelli:analyze` 在 Phase 4 停止 | 差距分析 + 偏差评估（改造量） |
  | 研发团队 | `/intelli:analyze` 完整执行 | Markdown 报告 + 接入 checklist |
  ```

  替换为：
  ```markdown
  ## 各角色适用场景

  分析开始时 Claude 会询问你的身份，整个对话和最终报告都将按角色定制。

  | 角色 | 对话风格 | 专属报告 |
  |------|---------|---------|
  | PM / 交付 | 业务语言，不展示 API 细节，聚焦结论与工作量 | `pm.md`：结论、建议、工作量、风险 |
  | 产品 / 架构 | 适量技术深度，强调系统边界与决策点 | `arch.md`：数据流、架构决策、前置条件 |
  | 研发 | 完整技术细节，主动展示 API 端点与差距 | `dev.md`：差距分析、工作量明细、接入 Checklist |
  | Claude（AI 开发） | 结构化输出，为 writing-plans 优化 | `spec.md`：需求规格、验收标准、依赖 |

  四份报告**总是全部生成**，对话中仅完整展示当前角色对应的那份，其余给文件路径。
  ```

- [ ] **Step 2: 替换"报告输出位置"章节**

  找到：
  ```markdown
  ## 报告输出位置

  报告保存至当前工作目录：

  ```
  docs/platform-analysis/YYYY-MM-DD-{platform-name}.md
  ```
  ```

  替换为：
  ```markdown
  ## 报告输出位置

  每次分析生成四份文档，保存至子目录：

  ```
  docs/platform-analysis/YYYY-MM-DD-{platform-name}/
    pm.md      # PM / 交付版
    arch.md    # 产品 / 架构版
    dev.md     # 研发版
    spec.md    # Claude Spec（writing-plans 输入）
  ```
  ```

- [ ] **Step 3: 更新 Skills 列表中 `intelli:report` 描述**

  找到：
  ```
  | `intelli:report` | 生成双层可行性报告 / 链路模式报告 |
  ```

  替换为：
  ```
  | `intelli:report` | 生成角色定制的四份报告文档（pm/arch/dev/spec），按角色展示对应文档 |
  ```

- [ ] **Step 4: 确认三处修改均已生效**

  读取 `README.md`，确认：
  - 角色表格为新版四行（pm/arch/dev/claude）
  - 报告路径展示子目录四文件格式
  - Skills 列表中 report 描述已更新

- [ ] **Step 5: Commit**

  ```bash
  git add README.md
  git commit -m "docs: update README for role-aware report system"
  ```

---

### Task 5: 版本号 Bump

skill 文件有功能性变更，升 minor 版本。

**Files:**
- Modify: `package.json`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`

- [ ] **Step 1: 将三个文件的版本从 `2.2.0` 升至 `2.3.0`**

  编辑 `package.json`：`"version": "2.3.0"`
  编辑 `.claude-plugin/plugin.json`：`"version": "2.3.0"`
  编辑 `.claude-plugin/marketplace.json`：`"version": "2.3.0"`

- [ ] **Step 2: Commit**

  ```bash
  git add package.json .claude-plugin/plugin.json .claude-plugin/marketplace.json
  git commit -m "chore: bump version to 2.3.0 for role-aware report system"
  ```
