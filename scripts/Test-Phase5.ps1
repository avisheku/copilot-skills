param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

$g = Test-SkillsGraph -Root $Root
Assert $g.Pass "skills.graph ($($g.Issues.Count) issues)"

$loop = Invoke-LoopRun -MaxIterations 1 -Root $Root
Assert ($loop.Count -eq 1) "loop one iteration"

$wire = ConvertTo-WireEnvelope -Payload @{ test = 1 } -Root $Root
Assert ($wire -match 'compact-json') "wire envelope compact-json"

$depth = Get-PackConfig -Name 'research\depth.json' -Root $Root
Assert ($depth.defaultMaxDepth -eq 1) "research depth default 1"

Assert (Test-Path (Join-Path $Root 'scripts\linux\install.sh')) "linux install.sh"
Assert (Test-Path (Join-Path $Root 'skills\magic\SKILL.md')) "magic alias skill"
Assert (Test-Path (Join-Path $Root 'docs\DEFER.md')) "DEFER doc"

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 5: all passed."
