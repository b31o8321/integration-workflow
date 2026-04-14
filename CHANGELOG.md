# Changelog

All notable changes to the Intelli plugin are documented here.

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
