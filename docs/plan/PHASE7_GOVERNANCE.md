# Phase 7 — Testability, Observability & AI Governance

| Field | Value |
|-------|-------|
| **Status** | Implemented |
| **Depends on** | Phase 6 MoA + CI branch protection |
| **Next** | [PHASE8_QUALITY_GATE.md](PHASE8_QUALITY_GATE.md) · [PHASE9_COMPARE_TRACKER.md](PHASE9_COMPARE_TRACKER.md) |
| **Also** | [CI.md](../CI.md) · [ACCEPTANCE.md](../../ACCEPTANCE.md) · [HANDBOOK.md](../HANDBOOK.md)

## Problem

CI blocked structure breaks but not silent prompt/ACCEPTANCE/handbook degrade after `/learn`. Stats were measurable CLI only (no local dashboard).

## Layers (ADR §9)

| Layer | Gate | Where |
|-------|------|-------|
| **L1** | InstallSmoke + schema + golden shape + learn negative | `Test-CI` → InstallSmoke + `Test-Phase7` |
| **L2** | Fixtures + VERIFY/marker preserve | `Invoke-LearnPromote` / handbook patch + Phase7 |
| **L3** | Static marker goldens (promptfoo stub filled) | Phase7 static; promptfoo manual only — never sole merge gate |

## Deliverables

- `scripts/Test-Phase7.ps1` — governance gate
- `scripts/Export-LocalDashboard.ps1` → `evidence/dashboard.html`
- `scripts/modules/Schema.psm1`, `Governance.psm1`
- Stronger `Test-LearnUpgradeOnly` (markers) + promote L1/L2 gate
- `shared/fixtures/l2-*.json`, `l3-static-markers.json`, `golden-path.shape.json`
- CI artifact: dashboard HTML

## Local

```powershell
.\scripts\Test-CI.ps1
.\scripts\Invoke-Stats.ps1 -Html
# open evidence\dashboard.html
```

## Non-goals

OTel · Langfuse · LLM-as-judge on every PR · Copilot-session eval harnesses (see DEFER)
