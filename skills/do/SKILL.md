---
name: do
description: Clarify, research, confirm ShortPlan, model-aware implement, 2080, handoff.
---

# /do

Orchestrate end-to-end. Follow `shared/instructions/gate-flow.md`.

## Procedure

1. **Prep (deterministic)** — `scripts/Invoke-DoPrep.ps1` (MCP snapshot, minimal, context pack, model tips).
2. **Gate 1 — Clarify** — goal, scope, done, constraints.
3. **Gate 2 — Research** — delegate `/research` (`shared/fixtures/delegatesTo-research.json`); depth one; native fork if parallel.
4. **Re-clarify** if scope changed.
5. **Gate 3 — ShortPlan** — user confirm yes. `New-ShortPlan` / `Confirm-Plan`.
6. **Gate 4 — Implement** — FullPlan for `agents/do.agent.md` workers only. Model tips at worker boundary via `Invoke-ModelTipInject`.
7. **Gate 5 — `/2080`** — ≤ five recommendations.
8. **Finish** — `scripts/Invoke-DoFinish.ps1` (restore context, model, MCP; handoff if `Test-SessionTokenThreshold` warns).

## Native parallel

After confirm only. Independent steps → native fork / `context: fork`. Sequential for gates, secrets, promote.

## Session tokens

`Test-SessionTokenThreshold` — soft warn → offer handoff; hard stop → `New-HandoffPack` + new chat.

## delegatesTo

`research`, `2080`
