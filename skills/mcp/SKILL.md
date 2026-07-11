---
name: mcp
description: Switch MCP profile explicitly; restore minimal after work.
---

# /mcp

Explicit MCP profile switch — never leave heavy profiles always-on.

## Commands

```powershell
Import-Module .\scripts\modules\CopilotSkills.psm1 -Force
Set-McpProfile -ProfileId minimal
Set-McpProfile -ProfileId dev
Restore-McpMinimal
```

Profiles: `config/mcp/profiles.json`

## Rules

- Default session: `minimal`
- Restore `minimal` after `/do` completes
