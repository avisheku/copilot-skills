# Shared dual-gate flow (do + research)

Used by `/do` and `/research`. Gates are **process** — hooks do not replace them.

## Gate 1 — Clarify (before research)

Ask until intent is clear:

- What is the goal?
- What is in scope / out of scope?
- What does done look like?
- Constraints (time, tools, risk)?

Do not research or implement until Gate 1 is answered.

## Gate 2 — Research

Delegate to `/research` or inline research. Depth **one** by default.

After research: clarify again if findings change scope.

## Gate 3 — Confirm

Produce **ShortPlan** (user-facing, concise). User must confirm yes before implement.

**FullPlan** is for workers/subagents only — never skip ShortPlan.

## Gate 4 — Implement

Only after confirm. Native parallel only for independent tasks after confirm.

## Gate 5 — Finish

Run `/2080` for ≤ five recommendations.  
If session soft-warn: `Invoke-ContextCompact` (lean pack + prune) then continue or handoff.  
Hard stop: handoff pack + **new chat**. Never rehydrate full tip dumps after compact.

## Re-open gates

New user input → re-research → update plans → confirm again.
