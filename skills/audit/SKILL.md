---
name: audit
description: Search ledger and emit audit report with error-map cross-ref.
---

# /audit

```powershell
.\scripts\Invoke-Audit.ps1 -Report
.\scripts\Invoke-Audit.ps1 -Skill do -Outcome error
.\scripts\Invoke-Audit.ps1 -Session <id>
```

Report includes stats, error/deny counts, error-map ids, recent errors.

Feed candidates to `/learn` — user confirms promote.
