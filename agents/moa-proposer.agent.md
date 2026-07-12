---
name: moa-proposer
description: MoA proposer worker — answer query with assigned family tip card. Compact, accurate.
context: fork
user-invocable: false
disable-model-invocation: true
---

# moa-proposer

Invoked only by `/moa` after run plan exists.

1. Read assigned proposer block from MoA plan (`memory/moa/<runId>-plan.json`).
2. Apply tip card for that family.
3. Answer the query using `config/moa/proposer-system.md` rules.
4. Stay under `maxChars`. Correctness > terseness.
5. Return plain answer text only (no meta chatter).
