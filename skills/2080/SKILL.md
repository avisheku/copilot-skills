---
name: "2080"
description: Multi-role 20/80 Pareto review; essentials ladder; max five recommendations.
---

# /2080

Run after `/do` or on demand. Synthesize **≤ five** recommendations (impact × effort).

## Roles (config/2080/roles.json)

Read each lens from `config/2080/roles/*.md`:

1. end-user
2. approver
3. architect — apply `config/essentials/ladder.md`
4. implementer
5. security (Phase 4)
6. operator (Phase 4)

Optional: `component:{id}` for component-specific reviews.

## Output format

For each item (max five):

- role
- recommendation
- impact (high/med/low)
- effort (high/med/low)
- optional: feed to `/learn` staging (Phase 4)

## Rules

- Essentials first — reject overengineering
- No auto-apply; user decides
