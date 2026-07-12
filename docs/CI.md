# CI and merge control

Simple GitHub Actions gate. Green checks required before merge.

## What runs

Workflow: `.github/workflows/ci.yml`

```text
InstallSmoke → Phase2 → GoldenPath → Phase4 → Phase5 → Phase6 → Phase7 → Phase8 → Phase9
→ Export-LocalDashboard
```

Local: `.\scripts\Test-CI.ps1` · `.\scripts\Invoke-Stats.ps1 -Html`

Job name: **PowerShell gates**

## Layer matrix

| Layer | What | Merge block? |
|-------|------|----------------|
| L1–L2 | Structure, fixtures, promote gates | Yes |
| L3 static | Markers in Phase7 | Yes |
| L4 ICS | Phase8 baseline maxDrop | Yes |
| L5 compare | Phase9 Elo math smoke (no live model) | Yes (math/fixtures only) |
| Optional judge | quality-judge.yml | No |

Phase plans: [PHASE7](plan/PHASE7_GOVERNANCE.md) · [PHASE8](plan/PHASE8_QUALITY_GATE.md) · [PHASE9](plan/PHASE9_COMPARE_TRACKER.md) · [ACCEPTANCE](../ACCEPTANCE.md)

## Proof of harness (not merge)

```powershell
.\scripts\Seed-CompareDemo.ps1
.\scripts\Export-CompareReport.ps1
# evidence\compare\report.html
```

## Status

- Public repo; `master` requires **PowerShell gates**
- Dashboard artifact on Actions

## Admin note

`enforce_admins` may be off — prefer PRs so gates always run.
