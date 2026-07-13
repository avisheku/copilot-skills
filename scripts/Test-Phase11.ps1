param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

function Assert-True($cond, $msg) {
    if (-not $cond) { throw "ASSERT: $msg" }
    Write-Host "OK: $msg"
}

# Fresh evidence for deterministic recommend/promote
$runsDir = Join-Path $Root 'evidence\matrix\runs'
if (Test-Path $runsDir) { Remove-Item $runsDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $runsDir | Out-Null

# matrix + efforts
$m = Get-ModelMatrix -Root $Root
Assert-True ($null -ne $m.cells.implement) 'matrix cells.implement'
Assert-True ($m.ladder.enabled -eq $true) 'ladder enabled'
Assert-True (Test-Path (Join-Path $Root 'config\models\efforts\medium.md')) 'effort tip medium'

# evidence log
$run = Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'universal' -Effort 'medium' -Outcome 'ok' -TokensEst 100 -Root $Root
Assert-True (Test-Path $run.Path) 'evidence run file'
$stats = @(Get-MatrixCellStats -TaskKind 'implement' -Root $Root)
Assert-True ($stats.Count -ge 1) 'cell stats'

# seed more for recommend evidence path
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'universal' -Effort 'medium' -Outcome 'ok' -TokensEst 90 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'universal' -Effort 'medium' -Outcome 'ok' -TokensEst 110 -Root $Root | Out-Null
$rec = Get-RecommendedMatrixCell -TaskKind 'implement' -Root $Root
Assert-True ($rec.family -eq 'universal') 'recommend family'
Assert-True ($rec.effort -eq 'medium') 'recommend effort'
Assert-True ($rec.source -eq 'evidence') 'recommend from evidence (n>=3)'

# prep injects matrix
$prep = Invoke-MatrixDoPrep -TaskKind 'implement' -Root $Root
Assert-True ($prep.family -and $prep.effort) 'DoPrep matrix cell'
$state = Get-Content (Join-Path $Root 'memory\.model-state.json') -Raw | ConvertFrom-Json
Assert-True ($null -ne $state.effortTips -or $state.effort) 'model state has effort'

# escalate + synth pack
$esc = Invoke-LadderEscalate -TaskKind 'implement' -Query 'fix flaky test' `
    -CurrentFamily 'universal' -CurrentEffort 'medium' -StepIndex 0 `
    -AttemptSummary 'failed verify' -WhatWorked 'repro found' -Blockers 'flake' `
    -NextAsk 'stabilize with seed' -Root $Root
Assert-True ($esc.Next.family -eq 'universal') 'escalate step0 family'
Assert-True ($esc.Next.effort -eq 'high') 'escalate step0 effort high'
Assert-True (Test-Path $esc.Pack.JsonPath) 'synth pack json'
Assert-True (Test-Path $esc.Pack.MdPath) 'synth pack md'

$esc2 = Invoke-LadderEscalate -TaskKind 'implement' -Query 'fix flaky test' `
    -CurrentFamily 'universal' -CurrentEffort 'high' -StepIndex 1 `
    -AttemptSummary 'still failing' -Root $Root
Assert-True ($esc2.Next.family -eq 'anthropic') 'escalate step1 family anthropic'

# learn matrix-cell staging + promote gate
# Make anthropic/medium look better: 3 oks
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 50 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 40 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 45 -Root $Root | Out-Null

$proposal = New-MatrixCellProposal -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Root $Root
$stagePath = Join-Path $Root "share\learnings\matrix-cell\$($proposal.id).json"
Assert-True (Test-Path $stagePath) 'matrix-cell staging'

$gate = Test-MatrixCellPromoteGate -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Root $Root
Assert-True ($gate.Pass) 'promote gate passes for better cell'

# Promote then restore seed start for repo cleanliness
$before = Get-Content (Join-Path $Root 'config\models\matrix.json') -Raw
Invoke-MatrixCellPromote -StagingFile $stagePath -Root $Root | Out-Null
$afterObj = Get-ModelMatrix -Root $Root
Assert-True ($afterObj.cells.implement.start.family -eq 'anthropic') 'promoted start family'
Assert-True ($afterObj.cells.implement.source -eq 'learn') 'promoted source learn'

# Restore seed so CI is deterministic for others
$restore = $before | ConvertFrom-Json
# keep evidence but reset cell start to seed
$restore.cells.implement.start.family = 'universal'
$restore.cells.implement.start.effort = 'medium'
$restore.cells.implement.source = 'seed'
$restore.cells.implement.updatedAt = $null
($restore | ConvertTo-Json -Depth 10) | Set-Content (Join-Path $Root 'config\models\matrix.json') -Encoding utf8
Assert-True ((Get-ModelMatrix -Root $Root).cells.implement.start.family -eq 'universal') 'restored seed start'

# learn.json has matrix-cell
$learn = Get-LearnConfig -Root $Root
Assert-True ($learn.kinds -contains 'matrix-cell') 'learn kind matrix-cell'

Write-Host 'Phase 11: all passed.'
exit 0
