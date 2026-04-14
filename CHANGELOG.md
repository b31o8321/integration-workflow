# Changelog

All notable changes to the Intelli plugin are documented here.

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
