param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

$map = @(Get-ErrorMapEntries -Root $Root)
Assert ($map.Count -ge 3) "error-map entries ($($map.Count))"

$staging = New-LearnStaging -Kind 'sync' -Title 'test' -Body 'upgrade body content here' -Root $Root
Assert ($staging.id) "learn staging created"

$tmp = Join-Path $env:TEMP "learn-staging-test.txt"
'long content for upgrade test' | Set-Content $tmp
$target = Join-Path $env:TEMP "learn-target-test.txt"
'short' | Set-Content $target
$up = Test-LearnUpgradeOnly -StagingPath $tmp -TargetPath $target -Root $Root
Assert $up.Pass "upgrade-only allows growth"

Write-LedgerEntry -Skill 'test' -Tool 'phase4' -Outcome 'ok' -TokensEst 10 -Root $Root | Out-Null
$stats = Get-LedgerStats -Root $Root
Assert ($stats.Total -ge 1) "ledger stats"

$audit = Invoke-AuditReport -Root $Root
Assert ($audit.errorMapIds.Count -ge 3) "audit report error-map ids"

$roles = (Get-PackConfig -Name '2080\roles.json' -Root $Root).roles
Assert ($roles -contains 'security') "2080 security role"
Assert ($roles -contains 'operator') "2080 operator role"

$ops = @(Test-AllSkillsAbidance -Root $Root | Where-Object { $_.Skill -in @('learn','stats','audit') })
Assert ((@($ops | Where-Object { -not $_.Pass })).Count -eq 0) 'learn/stats/audit abidance'

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 4: all passed."
exit 0
