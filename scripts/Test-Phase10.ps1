param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

Assert (Test-Path (Join-Path $Root 'config\upgrade\registry.json')) 'registry.json'
$src = @(Get-ResearchSources -Root $Root)
Assert ($src.Count -ge 5) "research sources ($($src.Count))"

$scan = Invoke-UpgradeScan -Root $Root
Assert ($scan.components.Count -ge 8) "components $($scan.components.Count)"
Assert ($scan.frontierTopics.Count -ge 5) 'frontier topics'

$rep = Export-UpgradeReport -Root $Root -Scan $scan
Assert (Test-Path $rep.Json) 'report.json'
Assert (Test-Path $rep.Markdown) 'report.md'
Assert ($rep.Scan.summary.action -ge 0) 'summary action count'

# No hard fail on review-only tips; action items should be zero on healthy pack
Assert ($scan.summary.action -eq 0) "no action findings (got $($scan.summary.action))"

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 10: all passed."
exit 0
