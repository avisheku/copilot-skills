param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($cond, $msg) { if (-not $cond) { Write-Host "FAIL: $msg"; $script:fail++ } else { Write-Host "OK: $msg" } }

Assert (Test-Path (Join-Path $Root 'skills\do\SKILL.md')) 'do skill exists'
$budget = Test-DescriptionBudget -Root $Root
Assert $budget.Pass "description budget $($budget.Total)/$($budget.Max)"
$hooks = Test-HooksManifest -Root $Root
Assert $hooks.Pass 'hooks.json valid'

& (Join-Path $PSScriptRoot 'Install-CopilotSkills.ps1') -Target Copilot -Layer Folders | Out-Null
$sync = Sync-CopilotSkillsTarget -Check -Target Copilot -Root $Root
Assert (($sync | Where-Object { -not $_.InSync }).Count -eq 0) 'post-install sync'

$pack = Invoke-ContextPack -PackId 'default' -Root $Root
Assert ($pack.refs.Count -ge 1) 'context pack inject'
Restore-ContextDefault -Root $Root | Out-Null
Assert (-not (Test-Path (Get-StatePath -Root $Root))) 'context restore'

if ($fail -gt 0) { exit 1 }
Write-Host "Smoke: all passed."
exit 0
