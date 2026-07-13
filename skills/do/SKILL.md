---
name: do
description: Clarify, research, confirm ShortPlan, model-aware implement, 2080, handoff.
---

# /do

Orchestrate end-to-end. Follow `shared/instructions/gate-flow.md`.

## Procedure

1. **Prep (deterministic)** — `scripts/Invoke-DoPrep.ps1` (MCP snapshot, minimal, context pack, **living matrix** start). If `memory/.context-compact.md` exists from a prior compact, continue from that pack only.
2. **Gate 1 — Clarify** — goal, scope, done, constraints.
3. **Gate 2 — Research** — delegate `/research` (`shared/fixtures/delegatesTo-research.json`); depth one; native fork if parallel.
4. **Re-clarify** if scope changed.
5. **Gate 3 — ShortPlan** — user confirm yes. `New-ShortPlan` / `Confirm-Plan`.
6. **Gate 4 — Implement** — Prefer **Copilot Auto** (10% discount). Use `Invoke-LadderCascadePlan` for the rung list. After each attempt score quality 0..1 (`Get-NormalizedQualityScore` / dimensions). Escalate when fail **or** qualityBelow — matrix picks next **effort or family** per `escalatePolicy` until `Done` (ok + quality ≥ min) or maxSteps. Always attach synth pack. Log with `Save-MatrixEvidence.ps1 -QualityScore`.
7. **Context thrift (any time)** — If `Test-ShouldCompact` / soft token warn: ask user, then `scripts/Invoke-ContextCompact.ps1` (lean pack + prune ladder/matrix dumps + restore blank inject). Hard stop → handoff + **new chat**. Never dump full tip cards or chat history back into context after compact.
8. **Gate 5 — `/2080`** — ≤ five recommendations.
9. **Finish** — `scripts/Invoke-DoFinish.ps1`. Stage `/learn` **matrix-cell** when a better start cell is evidenced.

## Native parallel

After confirm only. Independent steps → native fork / `context: fork`. Sequential for gates, secrets, promote.

## Session tokens

`Test-SessionTokenThreshold` — soft warn → **compact** (or handoff); hard stop → `New-HandoffPack` + new chat. No fake IDE compact API — we compact SkillsForge artifacts only (ADR O4).

## delegatesTo

`research`, `2080`
