# Phase 9 — Harness Comparison Tracker

| Field | Value |
|-------|-------|
| **Status** | Implemented |
| **Depends on** | Phase 7–8 (deterministic + ICS) |
| **Proves** | Pack effectiveness vs solo / across models / MoA |

## Research basis

| Pattern | Sources |
|---------|---------|
| Pairwise Elo | LMSYS / LMArena |
| Quality + cost + latency | Artificial Analysis, TokenRate, Skiln |
| Same model, vary harness | Harness-Bench, harness-benchmark, Harness Effect arxiv |

## What it is

For the **same task card**, record arms:

- `solo` — bare model  
- `harness-do` / `harness-2080` — pack skills  
- `moa-lite` / `moa-full` — MoA  

Scoreboard: **Elo**, quality avg, tokens, $, quality-per-dollar, **harness lift vs solo**, per-skill lift.

## Commands

```powershell
.\scripts\Invoke-CompareRun.ps1 -TaskId t01-clarify-scope -ArmId harness-do -ModelId anthropic-opus -QualityPassRate 0.9 -TokensIn 1000 -TokensOut 400
.\scripts\Seed-CompareDemo.ps1
.\scripts\Export-CompareReport.ps1
# evidence\compare\report.html
.\scripts\Test-Phase9.ps1
```

## CI

`Test-Phase9.ps1` in `Test-CI` — Elo math + fixtures; **no live model**.

## Related

- [PHASE7_GOVERNANCE.md](PHASE7_GOVERNANCE.md) · [PHASE8_QUALITY_GATE.md](PHASE8_QUALITY_GATE.md) · [CI.md](../CI.md) · [ACCEPTANCE.md](../../ACCEPTANCE.md)
