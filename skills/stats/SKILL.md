---
name: stats
description: Ledger rollup — totals by skill, outcome, token estimates.
---

# /stats

Searchable JSONL ledger stats.

```powershell
.\scripts\Invoke-Stats.ps1
.\scripts\Invoke-Stats.ps1 -Tail 2000
.\scripts\Invoke-Stats.ps1 -Html
```

Output: `Get-LedgerStats` — total, by skill, by outcome, token sum.  
`-Html` writes `evidence/dashboard.html`.
