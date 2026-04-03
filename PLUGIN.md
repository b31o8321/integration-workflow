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
