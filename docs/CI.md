# CI and merge control

```text
InstallSmoke → Phase2 → GoldenPath → Phase4 → … → Phase10
→ Export-LocalDashboard
```

Local: `.\scripts\Test-CI.ps1`

Job: **PowerShell gates**

| Layer | What | Merge block? |
|-------|------|----------------|
| L1–L5 | Structure through compare smoke | Yes |
| `/upgrade` scan | Phase10 inventory (no live scrape) | Yes (scan health) |
| Optional LLM judge | quality-judge.yml | No |

Plans: [PHASE7](plan/PHASE7_GOVERNANCE.md) … [PHASE10](plan/PHASE10_UPGRADE.md) · [ACCEPTANCE](../ACCEPTANCE.md)

**Stay current:** `.\scripts\Invoke-UpgradeScan.ps1`  
**Prove harness:** `.\scripts\Seed-CompareDemo.ps1`
