---
name: learn
description: Upgrade-only learning; error-map; dual sync; handbook patches; matrix-cell. Root cause first.
---

# /learn

Promote improvements with **upgrade-only** gate. Root cause before fix.

## Kinds

`setup` · `sync` · `arch` · `playbook` · `token-save` · `context-save` · `caveman` · `handbook-fix` · `handbook-install` · `handbook-skill` · **`matrix-cell`**

## Workflow

1. Reproduce → classify (`learn/error-map/` or `New-ErrorMapEntry`)
2. Stage: `scripts/Invoke-Learn.ps1 -Kind <kind> -Title "..." -Body "..."`  
   - **matrix-cell:** `New-MatrixCellProposal -TaskKind implement -Family copilot-auto -Effort medium` → `share/learnings/matrix-cell/`
3. L1 (+ L2 if behavior change) pass
4. Promote:
   - Generic: `-Promote -StagingFile ... -TargetFile ... [-DualSync]`
   - Matrix: `Invoke-MatrixCellPromote -StagingFile ...` (evidence gate + **L2 + ICS** + patches `config/models/matrix.json`)
5. Handbook: `-Promote -Handbook -StagingFile ...` (VERIFY blocks must remain)

## Rules

- **Refuse degrade** — `Test-LearnUpgradeOnly` blocks shrink-without-replacement
- **matrix-cell** — need `n >= evidenceMin`, better okRate (or quality), and avgQuality ≥ task `qualityMin` when scored
- `-Sources` / `-Models` refresh: explicit user ask only
- Playbooks → `/create` for new blocks

## Scripts

`Invoke-Learn.ps1` · modules `Learn.psm1` · `Ladder.psm1` (recommend / quality)
