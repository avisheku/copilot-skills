param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

$graph = Test-SkillsGraph -Root $Root
Assert $graph.Pass "skills.graph.json valid"

$mvp = @(Test-AllSkillsAbidance -Root $Root | Where-Object { $_.Phase -eq 'mvp' })
$bad = @($mvp | Where-Object { -not $_.Pass })
Assert ($bad.Count -eq 0) "all MVP skills pass abidance ($($mvp.Count) skills)"

$gates = @(Get-GatePhases)
Assert ($gates.Count -ge 5) "gate phases defined"

$plan = New-ShortPlan -Goal 'test' -Steps @('one')
Assert ($plan.goal -eq 'test') "New-ShortPlan works"

& (Join-Path $PSScriptRoot 'Install-CopilotSkills.ps1') -Target Copilot -Layer Folders | Out-Null
$sync = @(Sync-CopilotSkillsTarget -Check -Target Copilot -Root $Root)
Assert ((@($sync | Where-Object { -not $_.InSync })).Count -eq 0) 'install + sync'

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 2: all passed."
exit 0
