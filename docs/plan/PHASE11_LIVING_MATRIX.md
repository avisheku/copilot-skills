# Phase 11 — Living matrix (expert 20% + Auto discount + quality cascade)

| Field | Value |
|-------|-------|
| **Status** | Implemented (+ standardized cascade / quality normalize) |
| **Product** | SkillsForge |
| **Tagline** | 20% Change. 80% Better. |

## Levers

1. **Evidence** — `evidence/matrix/runs/*.json` (optional `qualityScore` 0..1)
2. **Prefer Copilot Auto** — 10% premium discount; default start; raise Auto effort before leaving Auto
3. **Escalate on fail OR quality** — until `Done` (`ok` + quality ≥ task `qualityMin`) or `maxSteps`
4. **Task policy** — `escalatePolicy`: `effortThenFamily` (default) vs `familyThenEffort` (e.g. debug)
5. **Synth pack** — prior work only on escalate (no rediscovery)
6. **`/learn` matrix-cell** — promote better starts (evidence + **L2 + ICS** + avgQuality ≥ qualityMin)
7. **Quality rubric** — `config/models/quality-rubric.json` normalizes any task to 0..1

## Standardized cascade (any task)

```text
1. Invoke-LadderCascadePlan(taskKind) → ordered rungs (start + escalate path)
2. Run rung N with tip cards (family + effort) — state stores paths + short excerpts only
3. Score quality 0..1 (single score OR weighted dimensions)
4. Test-LadderShouldEscalate → Done? stop. Else next cell by policy:
     effortThenFamily → same-family effort up, then leave family
     familyThenEffort → on error/deny jump family sooner, then raise effort
5. Attach synth pack (field-capped); Save-MatrixEvidence with qualityScore
6. If context heavy / soft warn → Invoke-ContextCompact (lean pack + prune) before next rung
7. Repeat until Done or maxSteps
```

**Quality normalization:** same 0..1 scale across taskKinds; per-task `qualityMin` in rubric overrides (e.g. debug 0.80, research 0.70). Pattern matches FrugalGPT stop-judger + promptfoo `llm-rubric` threshold.

## Context thrift / compaction (never grow heavy)

Already had: ContextPack inject→restore, description budget, session soft/hard tokens, handoff pack, MoA proposal truncate, wire compact-JSON.

**Added (standardized):**

| Lever | Behavior |
|-------|----------|
| `Get-TextBudget` | Cap any string before it enters packs/state |
| Tip state thrift | `.model-state.json` stores tip **paths + ≤400 char excerpts**, not full tip dumps |
| Synth pack caps | Ladder synth fields truncated |
| `Invoke-ContextCompact` | Writes `memory/.context-compact.{json,md}` ≤ `maxPackChars`, restores blank inject, slims model-state, prunes old ladder/matrix runs |
| Soft warn | Compact (ask first unless `-SkipAsk`); continue from pack only |
| Hard stop | Handoff + **new chat** (ADR O4: no fake IDE compact API) |

Policy: `config/session-policy.json` → `contextCompact`.

## Industry base (what we build on)

| Practice | Source | SkillsForge use |
|----------|--------|-----------------|
| Sequential cascade + stop when quality OK | [FrugalGPT](https://github.com/stanford-futuredata/FrugalGPT) | `Invoke-LadderCascadePlan` + `Done` |
| 0..1 rubric + pass threshold | [promptfoo llm-rubric](https://www.promptfoo.dev/docs/configuration/expected-outputs/model-graded/llm-rubric/) | `Get-NormalizedQualityScore` |
| Preference / Elo model ranking | [LMArena](https://lmarena.ai) | Compare tracker Elo (Phase 9); weak for per-task routing alone |
| Provider effort knobs | Anthropic effort / OpenAI reasoning | Tip cards `low\|medium\|high\|extra` |
| Cost-aware routing | FrugalGPT / industry “cascade then upgrade” | Prefer Auto discount; effort before family |

**How industry picks model vs effort:** start cheap/general → raise reasoning effort → switch family only when quality/fail persists. Arena Elo ranks *models* globally; task routers need *local evidence* (our matrix cells). Quality judges normalize answers to a shared score so thresholds are comparable across tasks.

## Policy (implement seed)

```text
Start: copilot-auto + medium
  -> fail or quality < qualityMin
     -> copilot-auto + high   (keep discount)
     -> universal / anthropic (leave Auto)
Stop: ok AND qualityScore >= qualityMin
```

## Commands

```powershell
.\scripts\Invoke-DoPrep.ps1
# Select Auto in Copilot model picker
.\scripts\Save-MatrixEvidence.ps1 -TaskKind implement -Family copilot-auto -Effort medium -Outcome ok -QualityScore 0.9
.\scripts\Invoke-LadderEscalate.ps1 -Query '...' -Outcome ok -QualityScore 0.4
.\scripts\Test-Phase11.ps1
.\scripts\Test-SecretsAudit.ps1
```

## Related

[ADR-017](ADR.md) · [HANDBOOK](../HANDBOOK.md) · [SOURCES](../SOURCES.md) · [quality-rubric.json](../../config/models/quality-rubric.json)
