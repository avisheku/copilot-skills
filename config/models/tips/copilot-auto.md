# Copilot Auto (preferred start)

Maximize the **10% premium-request discount** while Auto can handle the task.

## Host action

- In VS Code / Copilot Chat / CLI: select **Auto** in the model picker (not a fixed frontier model).
- Stay on Auto for the whole attempt at this effort level.

## When Auto is best

- Implement / orchestrate / research at low–medium complexity.
- Tasks where Copilot's router can pick an efficient 0x–1x model.
- Default SkillsForge start cell unless evidence says otherwise.

## When to leave Auto

Only escalate when:
1. The attempt **fails** (verify/error/deny), or
2. **Quality is below** the matrix `qualityMin` gate (acceptable outcome but unsatisfactory quality).

Escalation order: raise **effort on Auto first**, then leave Auto for a named family — keep the synth pack so the next step builds on prior work.

## Notes

- Discount applies to paid Copilot plans on Auto routing (model multiplier × 0.9).
- Do not start on the strongest named model by default — that skips the discount.
