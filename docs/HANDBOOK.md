# Handbook — Copilot Skills Pack

Single guide of record. AI and human install paths share the same steps.

## Agent contract

1. Read this file before install or fix.
2. Run VERIFY after each phase.
3. Never invent paths.
4. Never skip gates.
5. On failure: Troubleshoot section + report ledger path.

## What this pack is

Office-safe skills harness: dual gates, native parallelism, model-aware `/do`, multi-role `/2080`, upgrade-only `/learn`.

Constitution: [PILLARS.md](PILLARS.md) · [PRINCIPLES.md](PRINCIPLES.md)  
Architecture: [plan/ADR.md](plan/ADR.md)

## Prerequisites

- Windows (primary)
- VS Code or Insiders with GitHub Copilot Chat
- PowerShell 5.1+
- Claude Code optional (same SKILL.md)
- Org: check `chat.plugins.enabled` for Layer A vs B

## Cursor setup (fewer permission prompts)

1. **File → Open Folder** → `C:\Users\avish\Documents\KnowledgeVault\projects\copilot-skills`
2. **Cursor Settings → Agents** → enable Auto-run / YOLO
3. Add allowlist: `git`, `gh`, `powershell`

See [CURSOR_COMPAT.md](CURSOR_COMPAT.md).

## Install

### Layer B (folders) — default

```powershell
cd C:\Users\avish\Documents\KnowledgeVault\projects\copilot-skills
.\scripts\Install-CopilotSkills.ps1 -Target Copilot -Layer Folders
```

VERIFY:
  command: `.\scripts\Sync-CopilotSkills.ps1 -Check`
  expect: exit 0
ON_FAIL:
  goto: Troubleshoot#install-layer-b

### Layer A (plugin)

If org allows `chat.plugins.enabled`, register repo as Agent Plugin (see `plugin.json`). If skills not visible, fall back to Layer B.

VERIFY:
  command: `Test-Path "$env:USERPROFILE\.copilot\skills\do\SKILL.md"`
  expect: True
ON_FAIL:
  goto: Troubleshoot#install-layer-a

### Smoke

VERIFY:
  command: `.\scripts\Test-InstallSmoke.ps1`
  expect: `Smoke: all passed.`

## Configure

1. Copy `env/shared.md.example` to `env/user.md`
2. Optional: `COPILOT_SKILLS_HOME`, `OBSIDIAN_VAULT`
3. MCP: `Restore-McpMinimal` or `/mcp minimal`

VERIFY:
  command: `Test-Path .\env\user.md`
  expect: True (after you create it)
ON_FAIL:
  goto: Troubleshoot#configure

## Golden path (MVP)

Automated:

```powershell
.\scripts\Test-GoldenPath.ps1
```

VERIFY:
  command: `.\scripts\Test-GoldenPath.ps1`
  expect: `Golden path PASSED`
ON_FAIL:
  goto: Troubleshoot#golden-path

Manual in Copilot Chat:

1. `/mcp minimal`
2. `/do` — tiny task (e.g. list repo top-level folders)
3. Confirm ShortPlan when asked
4. `/2080` — review ≤ five recommendations
5. Handoff if token threshold warns

Evidence written to `evidence/golden-path.json`.

## Day-to-day

| When | Use |
|------|-----|
| Real task end-to-end | `/do` |
| Research only | `/research` |
| After work / retrospective | `/2080` |
| Drift / upgrade | `/sync -Check` then sync |
| Heavy MCP | `/mcp` then restore minimal |
| New skill block | `/create` |
| Fix recurring issue | `/learn` |
| Metrics | `/stats` |
| Session review | `/audit` |

## Skill catalog

| Skill | Purpose |
|-------|---------|
| `/do` | Prep → gates → model-aware implement → 2080 → finish |
| `/research` | Gated research depth one |
| `/2080` | Multi-role 20/80 |
| `/sync` | Repo ↔ global |
| `/mcp` | MCP profiles |
| `/create` | Scaffold + abidance |
| `/learn` | Upgrade-only promote; error-map; handbook |
| `/stats` | Ledger rollup |
| `/audit` | Search + report → learn candidates |

## Learn workflow (Phase 4)

1. Messy session → `/audit -Report`
2. Classify → `learn/error-map/` or `New-ErrorMapEntry`
3. Stage → `.\scripts\Invoke-Learn.ps1 -Kind <kind> -Title "..." -Body "..."`
4. Tests pass → promote with `-Promote -DualSync`
5. PR to share improvements

VERIFY:
  command: `.\scripts\Test-Phase4.ps1`
  expect: `Phase 4: all passed.`

## Phase 5 extensions

| Item | Command |
|------|---------|
| `/loop` | `.\scripts\Invoke-Loop.ps1` |
| `/magic` | Alias → `/2080` |
| Linux | `scripts/linux/install.sh` (needs pwsh) |

Still deferred: [DEFER.md](DEFER.md)

VERIFY:
  command: `.\scripts\Test-Phase5.ps1`
  expect: `Phase 5: all passed.`

## Troubleshoot

### install-layer-a

Symptom: plugin skills not visible.  
Fix: org policy; use Layer B Folders install.

### install-layer-b

Symptom: skills missing under `~/.copilot/skills`.  
Fix: `.\scripts\Install-CopilotSkills.ps1 -Layer Folders`; check `env/user.md`.

### configure

Symptom: paths wrong.  
Fix: set `COPILOT_SKILLS_HOME` in `env/user.md`.

### golden-path

Symptom: Test-GoldenPath fails.  
Fix: run `Test-Phase2.ps1` then `Test-InstallSmoke.ps1`; read `evidence/golden-path.json` for failing step.

### sync-drift

Symptom: `Sync -Check` exit 1.  
Fix: `.\scripts\Repair-Drift.ps1` or sync without `-Check`.

### budget-exceeded

Symptom: install fails description budget.  
Fix: shorten skill `description` in frontmatter; max 1500 total.

## Upgrade / sync

```powershell
.\scripts\Sync-CopilotSkills.ps1 -Check
.\scripts\Sync-CopilotSkills.ps1
```

See [COMPAT.md](COMPAT.md) and [VERSIONS.md](VERSIONS.md).

## Uninstall

```powershell
.\scripts\Uninstall-CopilotSkills.ps1 -Target Copilot
```

## For agents

Copy-paste for Copilot: *Follow docs/HANDBOOK.md Agent contract. Run VERIFY after each step. Use exact repo path above.*
