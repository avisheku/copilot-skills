---
name: do
description: Clarify intent, research, confirm ShortPlan, implement to completion, then 2080.
---

# /do

Orchestrate work end-to-end. Follow `shared/instructions/gate-flow.md`.

## Procedure

1. **Gate 1 — Clarify** — ask before research (goal, scope, done, constraints).
2. **Gate 2 — Research** — delegate `/research` or inline; depth one.
3. **Re-clarify** if research changes scope.
4. **Gate 3 — ShortPlan** — user must confirm yes. Use `New-ShortPlan` helper if scripting.
5. **Gate 4 — Implement** — FullPlan for workers only. Native parallel after confirm.
6. **Gate 5 — `/2080`** — ≤ five recommendations.

## Helpers

- Gate: `scripts/modules/Gate.psm1`
- Context: `Invoke-ContextPack` then `Restore-ContextDefault`
- Ledger: `Write-LedgerEntry -Skill do`

## Rules

- Never implement before ShortPlan confirm.
- Never dump pack rules into global Copilot instructions.
- Restore MCP `minimal` after work.

## delegatesTo

`research`, `2080`
