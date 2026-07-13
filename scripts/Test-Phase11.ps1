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

# matrix + efforts + auto + rubric
$m = Get-ModelMatrix -Root $Root
Assert-True ($null -ne $m.cells.implement) 'matrix cells.implement'
Assert-True ($m.ladder.enabled -eq $true) 'ladder enabled'
Assert-True ($m.cells.implement.start.family -eq 'copilot-auto') 'seed start is copilot-auto'
Assert-True ($m.cells.implement.escalatePolicy -eq 'effortThenFamily') 'implement effortThenFamily'
Assert-True ($m.cells.debug.escalatePolicy -eq 'familyThenEffort') 'debug familyThenEffort'
Assert-True ($null -ne $m.families.'copilot-auto') 'copilot-auto family'
Assert-True (Test-Path (Join-Path $Root 'config\models\tips\copilot-auto.md')) 'auto tip card'
Assert-True (Test-Path (Join-Path $Root 'config\models\efforts\medium.md')) 'effort tip medium'
Assert-True (Test-Path (Join-Path $Root 'config\models\quality-rubric.json')) 'quality rubric'
Assert-True ([double]$m.ladder.qualityMin -gt 0) 'qualityMin set'
Assert-True ((Get-Content (Join-Path $Root 'skills\learn\SKILL.md') -Raw) -match 'matrix-cell') 'learn SKILL docs matrix-cell'

# seed recommend without evidence -> auto
$seedRec = Get-RecommendedMatrixCell -TaskKind 'implement' -Root $Root
Assert-True ($seedRec.family -eq 'copilot-auto') 'seed recommend auto'
Assert-True ($seedRec.effort -eq 'medium') 'seed recommend medium'

# cascade plan (FrugalGPT-style)
$plan = Invoke-LadderCascadePlan -TaskKind 'implement' -Root $Root
Assert-True ($plan.Rungs.Count -ge 2) 'cascade has rungs'
Assert-True ($plan.PreferAuto -eq $true) 'cascade prefers Auto'
Assert-True ($plan.StopWhen -match 'qualityScore') 'cascade stop on quality'

# quality normalize + task mins
$norm = Get-NormalizedQualityScore -Dimensions @{ correctness = 1; completeness = 1; clarity = 1; thrift = 1; safety = 1 } -TaskKind 'implement' -Root $Root
Assert-True ([double]$norm.score -ge 0.99) 'weighted dimensions normalize ~1'
Assert-True ((Get-TaskQualityMin -TaskKind 'debug' -Root $Root) -ge 0.8) 'debug qualityMin higher'
Assert-True ((Get-TaskQualityMin -TaskKind 'research' -Root $Root) -le 0.7) 'research qualityMin lower'

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

# quality gate: ok but low quality -> escalate; Done when ok+quality
$qGate = Test-LadderShouldEscalate -Outcome 'ok' -QualityScore 0.5 -TaskKind 'implement' -Root $Root
Assert-True ($qGate.ShouldEscalate -eq $true) 'qualityBelow triggers escalate'
Assert-True ($qGate.Reasons -contains 'qualityBelow') 'reason qualityBelow'
Assert-True ($qGate.Done -eq $false) 'not Done when quality low'

$okGate = Test-LadderShouldEscalate -Outcome 'ok' -QualityScore 0.9 -TaskKind 'implement' -Root $Root
Assert-True ($okGate.ShouldEscalate -eq $false) 'high quality stays put'
Assert-True ($okGate.Done -eq $true) 'Done when ok+quality'

# no escalate when quality ok
$noEsc = Invoke-LadderEscalate -TaskKind 'implement' -Query 'ok task' `
    -CurrentFamily 'copilot-auto' -CurrentEffort 'medium' -StepIndex 0 `
    -Outcome 'ok' -QualityScore 0.9 -Root $Root
Assert-True ($noEsc.Escalated -eq $false) 'no escalate when quality ok'
Assert-True ($noEsc.Done -eq $true) 'Done flag on no-escalate'

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

# debug: familyThenEffort jumps family on hard fail
$dbg = Invoke-LadderEscalate -TaskKind 'debug' -Query 'hard bug' `
    -CurrentFamily 'copilot-auto' -CurrentEffort 'high' -StepIndex 0 `
    -Outcome 'error' -Root $Root
Assert-True ($dbg.Next.family -eq 'anthropic') 'debug error jumps family'
Assert-True ($dbg.Next.policy -eq 'familyThenEffort') 'debug policy applied'

# prep injects matrix
$prep = Invoke-MatrixDoPrep -TaskKind 'implement' -Root $Root
Assert-True ($prep.family -eq 'copilot-auto') 'DoPrep prefers auto'
$state = Get-Content (Join-Path $Root 'memory\.model-state.json') -Raw | ConvertFrom-Json
Assert-True ($null -ne $state.effortExcerpt -or $state.effort -or $state.effortCard) 'model state has effort card/excerpt'

# learn matrix-cell staging + promote gate (quality considered)
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 50 -QualityScore 0.95 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 40 -QualityScore 0.94 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Outcome 'ok' -TokensEst 45 -QualityScore 0.96 -Root $Root | Out-Null

$proposal = New-MatrixCellProposal -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Root $Root
$stagePath = Join-Path $Root "share\learnings\matrix-cell\$($proposal.id).json"
Assert-True (Test-Path $stagePath) 'matrix-cell staging'

$gate = Test-MatrixCellPromoteGate -TaskKind 'implement' -Family 'anthropic' -Effort 'medium' -Root $Root
Assert-True ($gate.Pass) 'promote gate passes for better cell'
Assert-True ([double]$gate.QualityMin -gt 0) 'promote gate exposes qualityMin'

$before = Get-Content (Join-Path $Root 'config\models\matrix.json') -Raw
$promoted = Invoke-MatrixCellPromote -StagingFile $stagePath -Root $Root
Assert-True ($promoted.Gates -match 'L2') 'promote ran L2+ICS path'
$afterObj = Get-ModelMatrix -Root $Root
Assert-True ($afterObj.cells.implement.start.family -eq 'anthropic') 'promoted start family'
Assert-True ($afterObj.cells.implement.source -eq 'learn') 'promoted source learn'

# Restore seed so CI is deterministic
Set-Content -Path (Join-Path $Root 'config\models\matrix.json') -Value $before -Encoding utf8
Assert-True ((Get-ModelMatrix -Root $Root).cells.implement.start.family -eq 'copilot-auto') 'restored auto seed start'

$learn = Get-LearnConfig -Root $Root
Assert-True ($learn.kinds -contains 'matrix-cell') 'learn kind matrix-cell'

# reject low-quality promote candidate
Save-MatrixEvidenceRun -TaskKind 'research' -Family 'openai' -Effort 'high' -Outcome 'ok' -TokensEst 20 -QualityScore 0.4 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'research' -Family 'openai' -Effort 'high' -Outcome 'ok' -TokensEst 20 -QualityScore 0.35 -Root $Root | Out-Null
Save-MatrixEvidenceRun -TaskKind 'research' -Family 'openai' -Effort 'high' -Outcome 'ok' -TokensEst 20 -QualityScore 0.3 -Root $Root | Out-Null
$badGate = Test-MatrixCellPromoteGate -TaskKind 'research' -Family 'openai' -Effort 'high' -Root $Root
Assert-True (-not $badGate.Pass) 'promote rejects avgQuality below qualityMin'
Assert-True (($badGate.Issues -join ' ') -match 'avgQuality') 'quality issue reported'

# context compact + text budget
$tb = Get-TextBudget -Text ('x' * 100) -MaxChars 20
Assert-True ($tb.Length -le 20) 'text budget truncates'
$cpack = New-ContextCompactPack -Goal 'keep thrifty' -CompletedSteps @('a') -RemainingSteps @('b') -TaskKind 'implement' -Root $Root
Assert-True (Test-Path $cpack.JsonPath) 'compact pack json'
Assert-True ($cpack.Chars -le 3500) 'compact pack within maxChars'
$cinv = Invoke-ContextCompact -Goal 'keep thrifty' -CompletedSteps @('a') -RemainingSteps @('b') -SkipAsk -Root $Root
Assert-True ($cinv.Compacted -eq $true) 'context compacted'
Assert-True ($null -eq (Get-ActiveContextPack -Root $Root)) 'inject restored after compact'

Write-Host 'Phase 11: all passed.'
exit 0
