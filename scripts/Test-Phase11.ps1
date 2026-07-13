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

# matrix + efforts + auto
$m = Get-ModelMatrix -Root $Root
Assert-True ($null -ne $m.cells.implement) 'matrix cells.implement'
Assert-True ($m.ladder.enabled -eq $true) 'ladder enabled'
Assert-True ($m.cells.implement.start.family -eq 'copilot-auto') 'seed start is copilot-auto'
Assert-True ($null -ne $m.families.'copilot-auto') 'copilot-auto family'
Assert-True (Test-Path (Join-Path $Root 'config\models\tips\copilot-auto.md')) 'auto tip card'
Assert-True (Test-Path (Join-Path $Root 'config\models\efforts\medium.md')) 'effort tip medium'
Assert-True ([double]$m.ladder.qualityMin -gt 0) 'qualityMin set'

# seed recommend without evidence -> auto
$seedRec = Get-RecommendedMatrixCell -TaskKind 'implement' -Root $Root
Assert-True ($seedRec.family -eq 'copilot-auto') 'seed recommend auto'
Assert-True ($seedRec.effort -eq 'medium') 'seed recommend medium'

# evidence log
$run = Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'copilot-auto' -Effort 'medium' -Outcome 'ok' -TokensEst 100 -QualityScore 0.9 -Root $Root
Assert-True (Test-Path $run.Path) 'evidence run file'
$stats = @(Get-MatrixCellStats -TaskKind 'implement' -Root $Root)
Assert-True ($stats.Count -ge 1) 'cell stats'

# seed more for recommend evidence path (prefer auto on tie)
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'copilot-auto' -Effort 'medium' -Outcome 'ok' -TokensEst 90 -QualityScore 0.88 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'copilot-auto' -Effort 'medium' -Outcome 'ok' -TokensEst 110 -QualityScore 0.92 -Root $Root | Out-Null
$rec = Get-RecommendedMatrixCell -TaskKind 'implement' -Root $Root
Assert-True ($rec.family -eq 'copilot-auto') 'recommend family auto'
Assert-True ($rec.effort -eq 'medium') 'recommend effort'
Assert-True ($rec.source -eq 'evidence') 'recommend from evidence (n>=3)'

# quality gate: ok but low quality -> escalate
$qGate = Test-LadderShouldEscalate -Outcome 'ok' -QualityScore 0.5 -Root $Root
Assert-True ($qGate.ShouldEscalate -eq $true) 'qualityBelow triggers escalate'
Assert-True ($qGate.Reasons -contains 'qualityBelow') 'reason qualityBelow'

$okGate = Test-LadderShouldEscalate -Outcome 'ok' -QualityScore 0.9 -Root $Root
Assert-True ($okGate.ShouldEscalate -eq $false) 'high quality stays put'

# no escalate when quality ok
$noEsc = Invoke-LadderEscalate -TaskKind 'implement' -Query 'ok task' `
    -CurrentFamily 'copilot-auto' -CurrentEffort 'medium' -StepIndex 0 `
    -Outcome 'ok' -QualityScore 0.9 -Root $Root
Assert-True ($noEsc.Escalated -eq $false) 'no escalate when quality ok'

# escalate on qualityBelow - stay on auto, raise effort
$escQ = Invoke-LadderEscalate -TaskKind 'implement' -Query 'weak result' `
    -CurrentFamily 'copilot-auto' -CurrentEffort 'medium' -StepIndex 0 `
    -Outcome 'ok' -QualityScore 0.4 `
    -AttemptSummary 'worked but shallow' -Blockers 'qualityBelow' -Root $Root
Assert-True ($escQ.Escalated -eq $true) 'escalated on quality'
Assert-True ($escQ.Next.family -eq 'copilot-auto') 'quality escalate keeps auto first'
Assert-True ($escQ.Next.effort -eq 'high') 'quality escalate raises effort'
Assert-True (Test-Path $escQ.Pack.JsonPath) 'synth pack json'

# escalate on error step0
$esc = Invoke-LadderEscalate -TaskKind 'implement' -Query 'fix flaky test' `
    -CurrentFamily 'copilot-auto' -CurrentEffort 'medium' -StepIndex 0 `
    -Outcome 'error' -AttemptSummary 'failed verify' -WhatWorked 'repro found' -Blockers 'flake' `
    -NextAsk 'stabilize with seed' -Root $Root
Assert-True ($esc.Escalated -eq $true) 'escalated on error'
Assert-True ($esc.Next.family -eq 'copilot-auto') 'escalate step0 family auto'
Assert-True ($esc.Next.effort -eq 'high') 'escalate step0 effort high'

$esc2 = Invoke-LadderEscalate -TaskKind 'implement' -Query 'fix flaky test' `
    -CurrentFamily 'copilot-auto' -CurrentEffort 'high' -StepIndex 1 `
    -Outcome 'error' -AttemptSummary 'still failing' -Root $Root
Assert-True ($esc2.Next.family -eq 'universal') 'escalate step1 leaves auto to universal'

# prep injects matrix
$prep = Invoke-MatrixDoPrep -TaskKind 'implement' -Root $Root
Assert-True ($prep.family -eq 'copilot-auto') 'DoPrep prefers auto'
$state = Get-Content (Join-Path $Root 'memory\.model-state.json') -Raw | ConvertFrom-Json
Assert-True ($null -ne $state.effortTips -or $state.effort) 'model state has effort'

# learn matrix-cell staging + promote gate
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 50 -QualityScore 0.95 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 40 -QualityScore 0.94 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 45 -QualityScore 0.96 -Root $Root | Out-Null

$proposal = New-MatrixCellProposal -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Root $Root
$stagePath = Join-Path $Root "share\learnings\matrix-cell\$($proposal.id).json"
Assert-True (Test-Path $stagePath) 'matrix-cell staging'

$gate = Test-MatrixCellPromoteGate -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Root $Root
Assert-True ($gate.Pass) 'promote gate passes for better cell'

$before = Get-Content (Join-Path $Root 'config\models\matrix.json') -Raw
Invoke-MatrixCellPromote -StagingFile $stagePath -Root $Root | Out-Null
$afterObj = Get-ModelMatrix -Root $Root
Assert-True ($afterObj.cells.implement.start.family -eq 'anthropic') 'promoted start family'
Assert-True ($afterObj.cells.implement.source -eq 'learn') 'promoted source learn'

# Restore seed so CI is deterministic
Set-Content -Path (Join-Path $Root 'config\models\matrix.json') -Value $before -Encoding utf8
Assert-True ((Get-ModelMatrix -Root $Root).cells.implement.start.family -eq 'copilot-auto') 'restored auto seed start'

$learn = Get-LearnConfig -Root $Root
Assert-True ($learn.kinds -contains 'matrix-cell') 'learn kind matrix-cell'

Write-Host 'Phase 11: all passed.'
exit 0
