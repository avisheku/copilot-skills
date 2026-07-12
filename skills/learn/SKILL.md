---
name: learn
description: Upgrade-only learning; error-map; dual sync; handbook patches. Root cause first.
---

# /learn

Promote improvements with **upgrade-only** gate. Root cause before fix.

## Kinds

`setup` · `sync` · `arch` · `playbook` · `token-save` · `context-save` · `caveman` · `handbook-fix` · `handbook-install` · `handbook-skill`

## Workflow

1. Reproduce → classify (`learn/error-map/` or `New-ErrorMapEntry`)
2. Stage: `scripts/Invoke-Learn.ps1 -Kind <kind> -Title "..." -Body "..."`
3. L1 (+ L2 if behavior change) pass
4. Promote: `-Promote -StagingFile ... -TargetFile ... [-DualSync]`
5. Handbook: `-Promote -Handbook -StagingFile ...` (VERIFY blocks must remain)

## Rules

- **Refuse degrade** — `Test-LearnUpgradeOnly` blocks shrink-without-replacement
- `-Sources` / `-Models` refresh: explicit user ask only (Phase 4 config)
- Playbooks → `/create` for new blocks

## Scripts

`Invoke-Learn.ps1` · modules `Learn.psm1`
