# Changelog

All notable changes to the Intelli plugin are documented here.

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
