param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

$g = Test-SkillsGraph -Root $Root
Assert $g.Pass "skills.graph"

$plan = New-MoARunPlan -Query 'What is 2+2?' -ProfileId 'lite' -Root $Root
Assert ($plan.proposers.Count -eq 3) "lite has 3 proposers"
Assert ($plan.aggregator.family) "aggregator set"
$path = Save-MoARunState -Plan $plan -Root $Root
Assert (Test-Path $path) "plan saved"

$long = 'x' * 2000
$pack = New-MoAProposalPack -RunId $plan.runId -Proposals @(
    @{ id = 'a'; family = 'openai'; text = $long },
    @{ id = 'b'; family = 'google'; text = 'short ok' }
) -Root $Root
Assert ($pack.Pack.proposals[0].chars -le 1200) "proposal truncated"
Assert ($pack.Pack.count -eq 2) "pack count"

$msg = Get-MoAAggregatorUserMessage -Query 'What is 2+2?' -ProposalPack $pack.Pack
Assert ($msg -match 'short ok') "aggregator msg has proposal"

$prep = & (Join-Path $PSScriptRoot 'Invoke-MoA.ps1') -Query 'phase6 test' -Profile lite -Root $Root
Assert ($prep.runId) "Invoke-MoA prep"

$fin = & (Join-Path $PSScriptRoot 'Invoke-MoAFinish.ps1') -RunId $prep.runId -ProposalsJson '[{"id":"a","family":"openai","text":"four"},{"id":"b","family":"google","text":"4"}]' -TokensEst 50 -Root $Root
Assert (Test-Path $fin.aggregatorPrompt) "aggregator prompt file"

$cmp = Compare-MoAToBaseline -Root $Root
Assert ($null -ne $cmp.moaOkCount) "baseline compare works"

$ab = Test-AbidanceGate -SkillPath (Join-Path $Root 'skills\moa')
Assert $ab.Pass ("moa abidance" + $(if ($ab.Issues.Count) { ": $($ab.Issues -join '; ')" } else { '' }))

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 6: all passed."
exit 0
