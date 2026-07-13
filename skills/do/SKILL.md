---
name: do
description: Clarify, research, confirm ShortPlan, model-aware implement, 2080, handoff.
---

# /do

Orchestrate end-to-end. Follow `shared/instructions/gate-flow.md`.

## Procedure

1. **Prep (deterministic)** — `scripts/Invoke-DoPrep.ps1` (MCP snapshot, minimal, context pack, **living matrix** start cell: family + effort from evidence or seed).
2. **Gate 1 — Clarify** — goal, scope, done, constraints.
3. **Gate 2 — Research** — delegate `/research` (`shared/fixtures/delegatesTo-research.json`); depth one; native fork if parallel.
4. **Re-clarify** if scope changed.
5. **Gate 3 — ShortPlan** — user confirm yes. `New-ShortPlan` / `Confirm-Plan`.
6. **Gate 4 — Implement** — FullPlan for `agents/do.agent.md` workers only. Use injected family + effort tips. On stuck (verify fail / refuse / user stuck):
   - `scripts/Invoke-LadderEscalate.ps1` — raise **effort then family** with a **synth pack** (prior work only).
   - Ask user to switch model if family changed; continue from pack — do not rediscover.
   - Log outcomes: `scripts/Save-MatrixEvidence.ps1`.
7. **Gate 5 — `/2080`** — ≤ five recommendations.
8. **Finish** — `scripts/Invoke-DoFinish.ps1` (restore context, model, MCP; handoff if `Test-SessionTokenThreshold` warns). On success after escalate, stage `/learn` matrix-cell proposal when evidence supports a better start.

## Native parallel

After confirm only. Independent steps → native fork / `context: fork`. Sequential for gates, secrets, promote.

## Session tokens

`Test-SessionTokenThreshold` — soft warn → offer handoff; hard stop → `New-HandoffPack` + new chat.

## delegatesTo

`research`, `2080`
