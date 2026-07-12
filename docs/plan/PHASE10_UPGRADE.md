# Phase 10 — Upgrade / Frontier Scan

| Field | Value |
|-------|-------|
| **Status** | Implemented |
| **Command** | `/upgrade` |
| **Policy** | Explicit scan + agent research; no auto-scrape |

## Problem

AI tooling, models, and eval practices move fast. Without a structured upgrade path, the pack goes stale (tips, sources, CI, MoA, instructions).

## Solution

1. **Local inventory** (`Invoke-UpgradeScan`) — every registered component → `ok` / `review` / `action`
2. **Frontier checklist** — topics + curated source URLs
3. **Agent research** — fill gaps; propose upgrades
4. **Promote** — `/learn` upgrade-only + CI

## Commands

```powershell
.\scripts\Invoke-UpgradeScan.ps1
# evidence\upgrade\report.md
.\scripts\Test-Phase10.ps1
```

## Related

[SOURCES.md](../SOURCES.md) · [DEFER.md](../DEFER.md) · [PHASE9_COMPARE_TRACKER.md](PHASE9_COMPARE_TRACKER.md) · [CI.md](../CI.md)
