# Changelog

All notable changes to the Intelli plugin are documented here.

---

## [2.12.0] - 2026-04-17

### Changed
- **`skills/check-api/SKILL.md` Feature 1 新增能力行**：在"Fetch ticket messages"后新增"**Message sender role detection**"（Required）。分析阶段必须明确：平台是否有 role/author_type 字段？若无，userId 对 customer 和 agent 是否均非空？若是，需标注 webhook 必须传入 contactUserId 供对比（如 LiveAgent `{$contact_userid}`）。此检查缺失是 LiveAgent LastMessageRoleFilter 将所有消息误判为 ASSISTANT 的根因。
- **`skills/map-arch/SKILL.md` 映射表新增行**：`getMessages()` 下新增"role detection"条目，要求评估 API 是否能独立判断消息发送方角色，若不能则记录 workaround（webhook 变量补充）及 gap 级别。
- **`skills/report/SKILL.md` Checklist 补全**：`getMessages()` 条目新增 role 判断机制和所需 webhook 变量两个子项，确保 spec.md 在分析阶段就明确客户需配置的 webhook body 变量，而不是留到测试才发现。

---

## [2.11.0] - 2026-04-17

### Added
- **`knowledge-base/intelli-capabilities.md` Tars AI 回复架构**：新增独立章节，记录 Intelli-Tars 整体数据流、bizType 两大类型（邮件型 vs Inbox 型）、新平台在 Tars 的 5 项注册要求，以及 `FindExistTicketExtPt` 时间窗口合并 vs externalId 精确匹配两种模式对比
- **`skills/analyze/SKILL.md` 代码库检查扩展**：进入实现阶段前的 `/add-dir` 提示新增 `tars`（工单 AI 回复必须），brainstorming context block 新增 Tars 关键约定（bizType 类型选择、FindExistTicketExtPt 差异、ChannelAuthTypeEnum value 一致性要求）
- **`skills/report/SKILL.md` 工单AI回复 Checklist 重写**：分为 Intelli 和 Tars 两部分；Intelli 侧修正枚举为 `ChannelTypeEnum`（原为过时的 `ExternKeySourceEnum`），补全 `resolveCredential()` / `resolveCredentialByKey()` 覆盖项；Tars 侧新增 7 项完整注册 checklist（BizConstants / BizScenarioFactory / 全套扩展点）

---

## [2.10.0] - 2026-04-15

### Changed
- **`knowledge-base/intelli-capabilities.md` 新平台接入约定补全**（来自 LiveAgent 集成复盘，7 个测试问题的系统性修复）：
  - **插件注册第 3 处**：新增 `shulex-intelli-api/pom.xml` `<dependencies>` 为必须步骤（共 3 处，缺此项导致 `unsupported platform` 错误，之前文档只记录了 2 处）
  - **Webhook URL gateway 前缀约定**：对外展示的 URL 必须含 `/api_v2/intelli` 前缀，附参考 LINE 实现；后端路由本身无此前缀，gateway 转发时剥除
  - **`getSetting()` 必须含 `authed` 布尔字段**：前端依赖此字段判断授权状态，不能仅靠字段非空判断；未授权时返回 `authed=false` 的对象（不能返回 null）
  - **`DELETE /auth` 必须实现专用端点**：ChannelAuth 模式平台不得复用通用 `cancelChannel`（`DELETE /api_v2/intelli/channel`），后者只走 ExternKey 表，调用会抛 `No enum constant ExternKeySourceEnum.{PLATFORM}`
  - **所有 Controller 端点必须包 `ResponseResult<T>`**：遗漏时前端拦截器剥层后 `res?.data` 为 `undefined`；`useRequest` 需配 `formatResult: (res) => res?.data`

---

## [2.9.0] - 2026-04-14

### Changed
- **`intelli:analyze` 知识库新鲜度检查**：Phase 5 进入实现阶段前，若知识库超过 14 天未更新，自动提示；根据角色区分两种提示——有代码库（claude/研发）提示运行 `/intelli:update-kb`；无代码库（PM/arch）提示联系维护人员

---

## [2.8.0] - 2026-04-14

### Added
- **`knowledge-base/intelli-capabilities.md` 前端集成约定**：shulex-smart-service 目录结构、三个必改文件（integration.ts / Channel/index.tsx / integration/index.tsx）、API 端点命名约定、参考实现对照表
- **`knowledge-base/intelli-capabilities.md` Maven 子模块约定**：pom.xml 依赖结构、两处常见遗漏（父 pom modules 块 + spring.factories 注册）
- **`knowledge-base/intelli-capabilities.md` 测试规范**：单元测试必须覆盖的 6 个 test case + 运行命令；ClientTest 标准方法表 + @Ignore 约定；E2E 四步执行顺序 + 常见失败排查
- **`intelli:report` spec.md 测试模板**：单元测试展开为具体测试方法 + 运行命令；E2E 展开为 4 个步骤（授权验证 → Webhook 配置 → API 连通性 → 完整链路），加入 staging 日志验证步骤和常见失败排查

### Changed
- `shulex-intelli/CLAUDE.md` 新增多仓库协作约定（双仓库分工、开发顺序、分支命名、PR 顺序）

---

## [2.7.0] - 2026-04-14

### Changed
- **`intelli:analyze` 流程精简（消除冗余人工介入）**：
  - 角色选择去除：默认 `claude`，仅在用户明确提出 PM/架构/研发视角时切换
  - 分析模式选择合并为一次：Phase 1 末尾问"完整/快速/链路"，不再逐阶段询问
  - Checkpoint A/B/C 去除：选完整分析后 Phase 2→3→4→5 自动推进，无需逐步确认
  - 仅保留最终 Checkpoint（是否进入实现阶段）
  - `/add-dir` 提示扩展：同时提示添加 shulex-intelli 和 shulex-smart-service
  - `brainstorming` 传入 context 新增架构背景块（ChannelAuth 约定 + Webhook 入口 + Plugin 注册方式 + 前端参考），减少 subagent 提问

---

## [2.6.1] - 2026-04-14

### Changed
- **`intelli:retrospective` 双模式**：新增 Mode B（通用功能复盘），用于非集成项目的功能开发；Mode A 改名为集成项目复盘；Input 增加模式选择步骤
- **`shulex-intelli/CLAUDE.md` 复盘规则**：从"集成项目强制运行"改为"所有功能分支完成后询问"，区分集成 vs 通用两种复盘路径

---

## [2.6.0] - 2026-04-14

### Added
- **`intelli:retrospective` Skill**：新增复盘 Skill，集成项目开发完成后主动运行，更新知识库、修正 Skill 错误、提炼架构约定；输出标准格式复盘报告
- **`intelli:analyze` Post-Implementation 节**：新增"实现完成后"触发说明，要求 `finishing-a-development-branch` 完成后主动调用 `intelli:retrospective`
- **`shulex-intelli/CLAUDE.md` 集成项目复盘规则**：新增强制规则，每次集成分支完成后必须主动运行 `/intelli:retrospective`

---

## [2.5.0] - 2026-04-14

### Changed
- **`intelli:report` spec.md 验收标准**：从单行描述改为两层结构——自动化测试（单元测试 checklist）+ E2E 端对端测试（手动执行 checklist，含前置配置、API连通性、完整链路验证）；集成项目必须完成 E2E 测试方可视为交付
- **`intelli:map-arch` 枚举注册行**：从 `ExternKeySourceEnum`（已废弃）改为 `ChannelTypeEnum`，注明新平台必须覆盖 `resolveCredential()` + `resolveCredentialByKey()`，参考 `LineTicketPlugin`

### Added
- **`intelli-capabilities.md` 凭证模式对比表**：新增 ChannelAuth vs ExternKey 对比，ChannelAuth 标为新平台标准，ExternKey 标为遗留；含新平台接入 Checklist（凭证相关）
- **`intelli-capabilities.md` 集成验收要求**：新增 E2E 验收三层次说明（单元测试 / API连通性 / E2E端对端）及工单 AI 回复 E2E Checklist
- **`README.md`** 新增集成验收要求一节，说明两层验收标准

### Docs
- `intelli-capabilities.md` SPI 表：`resolveCredential()` 和 `resolveCredentialByKey()` 从"可选覆盖"改为"新平台必须覆盖"

---

## [2.4.0] - 2026-04-14

### Added
- **`intelli:check-api` Feature 4**：新增前端集成评估维度，在能力矩阵中输出 Drawer 规格（AUTH SECTION / FEATURE SETTINGS SECTION / MANUAL GUIDANCE），SUMMARY 新增 `前端集成` 行
- **`intelli:flow-analyze` Phase D**：在 Phase C 后新增前端集成汇总阶段，从 Phase B 步骤中聚合授权、功能配置、手工操作信息，传入 `intelli:report`
- **`intelli:report` 前端集成 section**：全部 8 份报告模板（4 标准 + 4 链路模式）新增前端集成内容，深度按角色递增：pm.md（ASCII Drawer 截面图）→ arch.md（授权机制 + Drawer 结构）→ dev.md（字段表 + 接口 + 状态描述）→ spec.md（完整 UI 规格：字段校验 / 状态机 / API 签名 / 错误处理）

### Changed
- `intelli:check-api` Feature 1 (工单 AI 回复) 表格对齐 Ticket v2 SPI：新增 `SPI Method` 列、新增 `Fetch ticket subject`（`getSubject`）行、"Webhook push" 语义改为"支持自定义 Webhook URL"
- Webhook 签名验证 Look-for 描述扩展至 HMAC-SHA256 以外的算法；`parseWebhook` 双重用途标注说明

### Chore
- Bumped `plugin.json` and `marketplace.json` to v2.4.0

---

## [2.3.0] - 2026-04-14

### Added
- Role-aware report generation: `intelli:report` now produces four role-specific documents — `pm.md`, `arch.md`, `dev.md`, `spec.md`
- Role detection in `intelli:analyze` Phase 1 — identifies current user role (PM / Architect / Developer / Product Spec) before reporting
- Role detection and delegation to `intelli:report` in `intelli:flow-analyze`

### Fixed
- Improved report skill template clarity and chain mode templates

### Docs
- Updated README to document the role-aware report system

---

## [2.2.0] - 2026-04

### Added
- VAPI voice capability details added to knowledge-base

---

## [2.1.0] - 2026-04

### Added
- Authorization model analysis across `intelli:check-api`, `intelli:report`, and `intelli:flow-analyze`

### Chore
- Synced `plugin.json` and `marketplace.json` to v2.1.0

---

## [2.0.1] - 2026-04

### Chore
- Updated knowledge-base with real codebase scan data from `shulex_intelli` and `shulex_gpt`

---

## [2.0.0] - 2026-04

### Added
- **Dual-mode analysis**: `intelli:analyze` now offers standard capability matrix mode or business flow validation mode
- **`intelli:flow-analyze`** skill — business chain validation with API-level detail and documentation links
- **`intelli:update-kb`** skill — analyzes shulex codebases and updates the knowledge-base capability registry
- Knowledge-base directory with platform capability files (VAPI, Zendesk, etc.)
- Chain mode report format in `intelli:report`
- Mode selection (standard vs flow) in `intelli:analyze` Phase 1

### Docs
- Added v2 plugin design spec and sample platform analysis reports

---

## [1.0.0] - 2026-03

### Added
- **`intelli:check-api`** — analyzes a third-party platform's API capabilities across Ticket AI Reply, Livechat, and Data Sync dimensions; supports optional live API validation with read/write/webhook three-track handling
- **`intelli:report`** — generates feasibility report documents from analysis results
- **`intelli:map-arch`** — maps platform API capabilities to the Shulex Intelli architecture (TicketEngine V2 SPI, Livechat engine, ISyncService)
- **`intelli:analyze`** — orchestrator skill: single entry point for full platform analysis flow

### Fixed
- Prerequisite step to detect industry and business goal before analysis
- Phase numbering renumbered to natural sequence (1–5)

### Infrastructure
- Plugin scaffold with install script
- `package.json` for Claude Code plugin discovery
- `marketplace.json` for Claude Code plugin marketplace support
- Flattened skills directory structure with `installed_plugins.json` registration
- README with installation and usage guide
