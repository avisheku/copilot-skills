---
name: compare
description: Record and rank harness vs solo runs — Elo, lift, cost, skill effectiveness.
---

# /compare

Prove pack effectiveness with Arena-style ranks (your tasks, not public leaderboards).

## Record a run

After you complete a task with a known arm + model:

```powershell
.\scripts\Invoke-CompareRun.ps1 -TaskId t01-clarify-scope -ArmId harness-do -ModelId anthropic-opus `
  -OutputText "..." -TokensIn 1200 -TokensOut 500 -LatencyMs 15000 -QualityPassRate 0.9
```

Arms: `solo` · `harness-do` · `harness-2080` · `moa-lite` · `moa-full`  
Tasks: `shared/fixtures/compare/tasks/*.json`

## Scoreboard

```powershell
.\scripts\Invoke-CompareStats.ps1 -Html
.\scripts\Export-CompareReport.ps1
# open evidence\compare\report.html
```

## Demo seed (no live model)

```powershell
.\scripts\Seed-CompareDemo.ps1
```
