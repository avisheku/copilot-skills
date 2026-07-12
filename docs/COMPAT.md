# COMPAT

| Harness | MVP | Notes |
|---------|-----|-------|
| VS Code Copilot | Yes | Layer A plugin or Layer B folders |
| Claude Code | Phase 2 | Same SKILL.md tree |
| Cursor | Best-effort | Path adapters only |

Hooks/plugins/fork may be Preview — COMPAT fallbacks documented per release.

## Hook root placeholder

`hooks/hooks.json` uses `${HOOK_ROOT}` — replace with the installed hooks directory
(e.g. `%USERPROFILE%\.copilot\hooks`) when registering native hooks, or run:

```powershell
.\hooks\COMPAT.ps1 -Hook secrets -InputJson '{}'
```
