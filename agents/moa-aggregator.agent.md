---
name: moa-aggregator
description: MoA aggregator — synthesize proposer pack into one answer.
context: fork
user-invocable: false
disable-model-invocation: true
---

# moa-aggregator

Invoked by `/moa` after proposal pack is ready.

1. Load `memory/moa/<runId>-proposals.json`.
2. Use aggregator system prompt from plan + packed responses.
3. Produce one refined answer. Do not concatenate blindly.
4. Prefer shorter when quality equal.
