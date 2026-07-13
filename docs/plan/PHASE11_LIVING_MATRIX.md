# Phase 11 — Living matrix (expert 20%)

| Field | Value |
|-------|-------|
| **Status** | Implemented |
| **Product** | SkillsForge |
| **Tagline** | 20% Change. 80% Better. |

## Three levers

1. **Evidence** — `evidence/matrix/runs/*.json` + ledger skill `matrix`
2. **Recommend + escalate** — `Get-RecommendedMatrixCell`; effort then family + synth pack (`evidence/ladder/`)
3. **`/learn` matrix-cell** — upgrade-only promote into `config/models/matrix.json`

## Commands

```powershell
.\scripts\Invoke-DoPrep.ps1
.\scripts\Save-MatrixEvidence.ps1 -TaskKind implement -Family universal -Effort medium -Outcome ok
.\scripts\Invoke-LadderEscalate.ps1 -Query '...' -CurrentFamily universal -CurrentEffort medium
.\scripts\Test-Phase11.ps1
```

## Related

[ADR](ADR.md) · [HANDBOOK](../HANDBOOK.md) · [DEFER](../DEFER.md)
