param(
    [Parameter(Mandatory)][string]$Id,
    [string]$Description,
    [ValidateSet('mvp','stub')][string]$Phase = 'mvp',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$skillDir = Join-Path $Root "skills\$Id"
if (Test-Path $skillDir) { throw "Skill already exists: $Id" }
New-Item -ItemType Directory -Force -Path $skillDir | Out-Null

$desc = if ($Description) { $Description } else { "Skill $Id" }
@"
---
name: $Id
description: $desc
---

# /$Id

Scaffolded by New-SkillScaffold.ps1. Edit before promote.
"@ | Set-Content (Join-Path $skillDir 'SKILL.md') -Encoding utf8

@{ id = $Id; version = '0.1.0'; phase = $Phase } | ConvertTo-Json | Set-Content (Join-Path $skillDir 'meta.json') -Encoding utf8
"# /$Id`n" | Set-Content (Join-Path $skillDir 'README.md') -Encoding utf8
"# /$Id setup`n" | Set-Content (Join-Path $skillDir 'SETUP.md') -Encoding utf8
"# /$Id acceptance`n- [ ] TBD`n" | Set-Content (Join-Path $skillDir 'ACCEPTANCE.md') -Encoding utf8

if ($Phase -eq 'mvp') {
    Invoke-CreateAbidanceGate -SkillPath $skillDir
}
Write-Host "Scaffolded skills/$Id — add to config/skills.graph.json"
