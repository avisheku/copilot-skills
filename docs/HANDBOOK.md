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

## Install

### Layer A (plugin)

```powershell
cd C:\Users\avish\Documents\KnowledgeVault\projects\copilot-skills
.\scripts\Install-CopilotSkills.ps1 -Target Copilot -Layer Folders
```

VERIFY:
  command: .\scripts\Sync-CopilotSkills.ps1 -Check
  expect: exit 0 (all in sync)
ON_FAIL:
  goto: Troubleshoot#install-layer-b

Smoke (full):
  command: .\scripts\Test-InstallSmoke.ps1
  expect: Smoke: all passed.

## Configure

1. Copy `env/shared.md.example` to `env/user.md`
2. Set `COPILOT_SKILLS_HOME` if non-default
3. MCP profile: `/mcp minimal`

## Golden path

1. Install (above)
2. `/mcp minimal`
3. `/do` — tiny task (e.g. list repo structure)
4. `/2080` — review recommendations
5. Handoff if token threshold hit
6. Ledger entry if hooks enabled

## Skill catalog

| Skill | Purpose |
|-------|---------|
| `/do` | Clarify → research → confirm → implement |
| `/research` | Research with same gates |
| `/2080` | Multi-role 20/80 recommendations |
| `/sync` | Repo ↔ global sync |
| `/mcp` | MCP profile switch |
| `/create` | Expert block scaffold |

## Troubleshoot

### install-layer-a

Symptom: plugin skills not visible.  
Fix: check org plugin policy; fall back to Layer B.

### install-layer-b

Symptom: folders missing.  
Fix: re-run Install with `-Layer Folders`; check paths in `env/user.md`.

## Upgrade / sync

```powershell
.\scripts\Sync-CopilotSkills.ps1 -Check
```

See [COMPAT.md](COMPAT.md) and [VERSIONS.md](VERSIONS.md).

## Uninstall

```powershell
.\scripts\Uninstall-CopilotSkills.ps1 -Target Copilot
```
