---
name: do-worker
description: Worker subagent for /do after ShortPlan confirm. Native fork target.
context: fork
user-invocable: false
disable-model-invocation: true
---

# do-worker

Invoked by `/do` after ShortPlan confirm only.

- Execute FullPlan steps
- Use model tip card injected at worker boundary
- `parallelGroup` in plan is schema only — use native fork for independent steps
- Report back to orchestrator; do not re-open gates without parent `/do`
