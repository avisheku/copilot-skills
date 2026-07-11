---
name: research
description: Research with dual gates; fan-out depth one; synthesize for ShortPlan.
disable-model-invocation: true
user-invocable: true
---

# /research

Same gates as `/do` for clarify/confirm. Research only — do not implement unless user escalates to `/do`.

## Procedure

1. Clarify what to research.
2. Fan-out depth **one** (native fork if available).
3. Synthesize findings for ShortPlan input.
4. Flag unknowns and sources.

## Helpers

- `shared/instructions/gate-flow.md`
- `docs/SOURCES.md` for frontier refs (on explicit ask)

## Output

Structured summary: findings, risks, recommended next steps, open questions.
