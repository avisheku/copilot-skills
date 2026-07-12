param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

$tasks = @(Get-CompareTasks -Root $Root)
Assert ($tasks.Count -ge 8) "compare tasks ($($tasks.Count))"
$arms = @(Get-CompareArms -Root $Root)
Assert ($arms.Count -ge 4) "compare arms ($($arms.Count))"
Assert (Test-Path (Join-Path $Root 'config\compare\prices.json')) 'prices.json'

# Fresh temp root for isolated scoring test
$tmp = Join-Path $env:TEMP ("compare-phase9-" + [guid]::NewGuid().ToString('n').Substring(0, 8))
New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'evidence\compare\runs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'shared\fixtures\compare\tasks') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'config\compare') | Out-Null
Copy-Item (Join-Path $Root 'config\compare\*') (Join-Path $tmp 'config\compare') -Recurse
Copy-Item (Join-Path $Root 'shared\fixtures\compare\tasks\*') (Join-Path $tmp 'shared\fixtures\compare\tasks')

# Write two synthetic runs into tmp via Save-CompareRun needs Get-CopilotSkillsRoot - override by -Root
$r1 = Save-CompareRun -Root $tmp -TaskId 't01-clarify-scope' -ArmId 'solo' -ModelId 'anthropic-opus' `
    -TokensIn 100 -TokensOut 50 -LatencyMs 1000 -QualityPassRate 0.4 -OutputText 'bare'
$r2 = Save-CompareRun -Root $tmp -TaskId 't01-clarify-scope' -ArmId 'harness-do' -ModelId 'anthropic-opus' `
    -TokensIn 150 -TokensOut 60 -LatencyMs 1200 -QualityPassRate 0.9 -OutputText 'gated'
Assert ($r1.runId) 'save solo run'
Assert ($r2.runId) 'save harness run'

$board = Invoke-CompareScoreboard -Root $tmp
Assert ($board.runCount -eq 2) "runCount $($board.runCount)"
Assert ($board.pairCount -ge 1) "pairCount $($board.pairCount)"
Assert ($board.leaderboard.Count -ge 2) 'leaderboard rows'
$harness = $board.leaderboard | Where-Object { $_.armId -eq 'harness-do' } | Select-Object -First 1
$solo = $board.leaderboard | Where-Object { $_.armId -eq 'solo' } | Select-Object -First 1
Assert ($harness.elo -gt $solo.elo) "harness Elo $($harness.elo) > solo $($solo.elo)"
Assert (@($board.lifts | Where-Object { $_.qualityLift -gt 0 }).Count -ge 1) 'positive harness lift'

$rep = Export-CompareReport -Root $tmp
Assert (Test-Path $rep.Html) 'report.html'
Assert (Test-Path $rep.Json) 'report.json'

# Seed demo in real repo (idempotent) + scoreboard
& (Join-Path $PSScriptRoot 'Seed-CompareDemo.ps1') -Root $Root | Out-Null
$demoBoard = Invoke-CompareScoreboard -Root $Root
Assert ($demoBoard.runCount -ge 8) "demo runs $($demoBoard.runCount)"
Assert ($demoBoard.leaderboard.Count -ge 2) 'demo leaderboard'

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 9: all passed."
exit 0
