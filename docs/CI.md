# CI and merge control

Simple GitHub Actions gate. Green checks required before merge.

## What runs

Workflow: `.github/workflows/ci.yml`

On every **push** and **pull request** to `master`/`main` (also `workflow_dispatch`):

```text
InstallSmoke → Phase2 → GoldenPath → Phase4 → Phase5 → Phase6 → Phase7 → Phase8
→ Export-LocalDashboard (evidence/dashboard.html)
```

Local:

```powershell
.\scripts\Test-CI.ps1
.\scripts\Invoke-Stats.ps1 -Html
# open evidence\dashboard.html
```

Job name (must match protection): **PowerShell gates**

## L1 / L2 / L3 / L4 matrix

| Layer | What | Merge block? |
|-------|------|----------------|
| **L1** | InstallSmoke (budget, hooks, ContextPack), Phase scripts, ledger schema, golden-path shape, learn shrink negative | Yes |
| **L2** | `shared/fixtures/l2-*.json`, VERIFY/marker preserve, `Invoke-L2PromoteGate` on `/learn` promote | Yes (CI + promote) |
| **L3** | Static markers (`l3-static-markers.json`) in Phase7; promptfoo manual | Static yes; LLM-judge no |
| **L4 / ICS** | Instruction Contract Score vs `evidence/quality-baseline.json` (`minAbsolute` + `maxDrop`) in Phase8 | Yes |
| **Optional judge** | `quality-judge.yml` + `promptfoo-llm.yaml` | No (`continue-on-error`) |

ICS ≠ live Copilot chat quality. Phase 7 = deterministic code/structure; Phase 8 = instruction-file score.

## Status (applied)

- Repo: **public** — https://github.com/avisheku/copilot-skills
- `master` protected: requires status check **PowerShell gates** (strict / up to date)
- Force-push and branch deletion: off
- Actions uploads `evidence/dashboard.html` + `golden-path.json` as artifact
- Admin can still push directly when `enforce_admins` is false — prefer PRs

## Local dashboard

```powershell
.\scripts\Export-LocalDashboard.ps1
# or
.\scripts\Invoke-Stats.ps1 -Html
```

Shows ledger KPIs plus **ICS score / baseline / drop** (labeled deterministic).

## Quality baseline refresh

After intentional instruction upgrades that pass CI:

```powershell
.\scripts\Update-QualityBaseline.ps1
```

Do not auto-refresh on every merge (avoids baseline creep).

## How merges work

```text
feature branch → push → CI runs → open PR
                         ↓
              PowerShell gates green? → merge allowed
                         ↓ red
              fix → push again → CI re-runs → merge blocked until green
```

## Fail = reject

| Result | Action |
|--------|--------|
| CI green | Merge PR |
| CI red | Do not merge; fix and push |
| Optional judge red | Informational only until you promote it |
