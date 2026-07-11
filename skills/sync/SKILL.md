---
name: sync
description: Sync repo skills to global install; per-skill drift check with -Check.
---

# /sync

Repo ↔ global skill folders. Deterministic — use scripts.

## Commands

```powershell
.\scripts\Sync-CopilotSkills.ps1 -Check
.\scripts\Sync-CopilotSkills.ps1
.\scripts\Sync-CopilotSkills.ps1 -Skill do -Target Copilot
```

## Targets

Copilot · Claude · Cursor (best-effort)

## On drift

Run `Repair-Drift.ps1` or sync without `-Check`.
