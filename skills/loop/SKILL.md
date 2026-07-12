---
name: loop
description: Repeat audit then 2080 review; reuses models config. Manual invoke only.
disable-model-invocation: true
---

# /loop

Periodic improvement loop — **manual** via script (no daemon).

```powershell
.\scripts\Invoke-Loop.ps1
.\scripts\Invoke-Loop.ps1 -Iterations 2
```

Config: `config/loop.json` — steps `audit`, `2080`.

Reuses: `Invoke-AuditReport`, `/2080` roles, model tips path.

Enable `loop.json` `enabled: true` only when you want repeated iterations.
