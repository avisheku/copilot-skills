# Phase 11 — Living matrix (expert 20% + Auto discount)

| Field | Value |
|-------|-------|
| **Status** | Implemented |
| **Product** | SkillsForge |
| **Tagline** | 20% Change. 80% Better. |

## Levers

1. **Evidence** — `evidence/matrix/runs/*.json` (includes optional `qualityScore`)
2. **Prefer Copilot Auto** — 10% premium discount; default start cell; raise Auto effort before leaving Auto
3. **Escalate on fail OR quality** — `Test-LadderShouldEscalate` (`error` / `deny` / `qualityBelow` vs `qualityMin`)
4. **Synth pack** — prior work only on escalate
5. **`/learn` matrix-cell** — promote better starts when evidence wins

## Policy

```text
Start: copilot-auto + medium
  -> fail or quality < qualityMin
     -> copilot-auto + high   (keep discount)
     -> universal / anthropic (leave Auto)
```

## Commands

```powershell
.\scripts\Invoke-DoPrep.ps1
# Select Auto in Copilot model picker
.\scripts\Save-MatrixEvidence.ps1 -TaskKind implement -Family copilot-auto -Effort medium -Outcome ok -QualityScore 0.9
.\scripts\Invoke-LadderEscalate.ps1 -Query '...' -Outcome ok -QualityScore 0.4
.\scripts\Test-Phase11.ps1
```

## Related

[ADR-017](ADR.md) · [HANDBOOK](../HANDBOOK.md) · [SOURCES](../SOURCES.md)
