# Phase 8 — Instruction Quality Gate (ICS)

| Field | Value |
|-------|-------|
| **Status** | Implemented |
| **Depends on** | Phase 7 governance |
| **Merge gate** | Deterministic Instruction Contract Score vs baseline (`maxDrop`) |
| **Optional** | LLM judge workflow (`continue-on-error`) |

## Split with Phase 7

| Layer | Owns |
|-------|------|
| Phase 7 | Deterministic code/structure/contracts (PowerShell, markers, L2, static L3) |
| Phase 8 | Weighted ICS on prompt/md files + baseline regression |

## How ICS works

1. Cases: `shared/fixtures/l4-quality-cases.json`
2. Score: weighted pass rate 0..1 (`Quality.psm1`)
3. Baseline: `evidence/quality-baseline.json` (`casesVersion` = SHA256 of cases file)
4. Fail if `score < minAbsolute` (0.85) **or** `baseline - score > maxDrop` (0.05)
5. Config: `config/evals/quality-gate.json`

```powershell
.\scripts\Test-Phase8.ps1
.\scripts\Update-QualityBaseline.ps1   # only after intentional green upgrades
```

## Research base (patterns, not vendored)

- Promptfoo CI thresholds / path filters
- Baseline + maxDrop (agent-evals-template, eval-gate)
- agentskills.io evals.json assertions

## Risks (summary)

False confidence, gaming, over-blocking learn, baseline creep — mitigated by minAbsolute+maxDrop, casesVersion hash, path-scoped promote, judge never required. See plan Phase8 risks table.

## Optional judge

`.github/workflows/quality-judge.yml` — needs `OPENAI_API_KEY`; skips otherwise; **not** branch-protection required.
