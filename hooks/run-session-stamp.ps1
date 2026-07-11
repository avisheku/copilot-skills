param([string]$InputJson = '{}')
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path $PSScriptRoot -Parent
$env:COPILOT_SKILLS_SESSION = [guid]::NewGuid().ToString('n').Substring(0, 12)
Import-Module (Join-Path $root 'scripts\modules\CopilotSkills.psm1') -Force
Write-LedgerEntry -Skill 'session' -Tool 'SessionStart' -Outcome 'ok' -Session $env:COPILOT_SKILLS_SESSION -Root $root | Out-Null
Write-Output '{"continue":true}'
