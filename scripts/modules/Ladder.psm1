# SkillsForge — living matrix ladder (Phase 11+)

# Evidence, Copilot Auto discount preference, quality-gate escalate, synth packs.

function Get-MatrixRunsDir {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'evidence\matrix\runs'
}

function Get-LadderConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $m = Get-ModelMatrix -Root $Root
    if ($m.ladder) { return $m.ladder }
    return [pscustomobject]@{
        enabled                   = $true
        preferEffortBeforeFamily  = $true
        preferDiscountFamily      = 'copilot-auto'
        maxSteps                  = 3
        evidenceMin               = 3
        qualityMin                = 0.75
        escalateOn                = @('error', 'deny', 'qualityBelow')
    }
}

function Get-EffortTipCard {
    param(
        [ValidateSet('low', 'medium', 'high', 'extra')][string]$Effort = 'medium',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $path = Join-Path $Root "config\models\efforts\$Effort.md"
    if (-not (Test-Path $path)) { return '' }
    return Get-Content $path -Raw
}

function Save-MatrixEvidenceRun {
    param(
        [Parameter(Mandatory)][string]$TaskKind,
        [Parameter(Mandatory)][string]$Family,
        [Parameter(Mandatory)][string]$Effort,
        [ValidateSet('ok', 'warn', 'deny', 'error')][string]$Outcome = 'ok',
        [int]$TokensEst = 0,
        [Nullable[double]]$QualityScore = $null,
        [string]$EscalatedFrom = '',
        [string]$EscalateReason = '',
        [string]$RunId = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $dir = Get-MatrixRunsDir -Root $Root
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    if (-not $RunId) { $RunId = [guid]::NewGuid().ToString('n').Substring(0, 12) }
    $ts = (Get-Date).ToUniversalTime().ToString('o')
    $run = [ordered]@{
        id             = $RunId
        taskKind       = $TaskKind
        family         = $Family
        effort         = $Effort
        outcome        = $Outcome
        tokensEst      = $TokensEst
        qualityScore   = if ($null -ne $QualityScore) { [double]$QualityScore } else { $null }
        escalatedFrom  = $EscalatedFrom
        escalateReason = $EscalateReason
        ts             = $ts
    }
    $path = Join-Path $dir "$RunId.json"
    ($run | ConvertTo-Json -Depth 4) | Set-Content $path -Encoding utf8

    Write-LedgerEntry -Skill 'matrix' -Tool "$TaskKind/$Family/$Effort" -Outcome $Outcome -TokensEst $TokensEst -Root $Root | Out-Null
    return [pscustomobject]@{ Run = $run; Path = $path }
}

function Get-MatrixEvidenceRuns {
    param(
        [string]$TaskKind = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $dir = Get-MatrixRunsDir -Root $Root
    if (-not (Test-Path $dir)) { return @() }
    $runs = @(Get-ChildItem $dir -Filter '*.json' | ForEach-Object {
        Get-Content $_.FullName -Raw | ConvertFrom-Json
    })
    if ($TaskKind) {
        $runs = @($runs | Where-Object { $_.taskKind -eq $TaskKind })
    }
    return $runs
}

function Get-MatrixCellStats {
    param(
        [string]$TaskKind = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $runs = @(Get-MatrixEvidenceRuns -TaskKind $TaskKind -Root $Root)
    $groups = @{}
    foreach ($r in $runs) {
        $key = '{0}|{1}|{2}' -f $r.taskKind, $r.family, $r.effort
        if (-not $groups.ContainsKey($key)) {
            $groups[$key] = [pscustomobject]@{
                taskKind = $r.taskKind
                family   = $r.family
                effort   = $r.effort
                n        = 0
                ok       = 0
                tokens   = New-Object System.Collections.Generic.List[int]
                quality  = New-Object System.Collections.Generic.List[double]
            }
        }
        $g = $groups[$key]
        $g.n++
        if ($r.outcome -eq 'ok') { $g.ok++ }
        if ($null -ne $r.tokensEst) { [void]$g.tokens.Add([int]$r.tokensEst) }
        if ($null -ne $r.qualityScore) { [void]$g.quality.Add([double]$r.qualityScore) }
    }
    $out = @()
    foreach ($key in $groups.Keys) {
        $g = $groups[$key]
        $tok = @($g.tokens)
        $median = 0
        if ($tok.Count -gt 0) {
            $sorted = @($tok | Sort-Object)
            $mid = [int][Math]::Floor(($sorted.Count - 1) / 2)
            $median = $sorted[$mid]
        }
        $qList = @($g.quality)
        $avgQ = $null
        if ($qList.Count -gt 0) {
            $sum = 0.0
            foreach ($q in $qList) { $sum += $q }
            $avgQ = [math]::Round($sum / $qList.Count, 4)
        }
        $okRate = if ($g.n -gt 0) { [math]::Round($g.ok / $g.n, 4) } else { 0 }
        $out += [pscustomobject]@{
            taskKind      = $g.taskKind
            family        = $g.family
            effort        = $g.effort
            n             = $g.n
            okRate        = $okRate
            medianTokens  = $median
            avgQuality    = $avgQ
            discountBoost = if ($g.family -eq 'copilot-auto') { 1 } else { 0 }
        }
    }
    # Prefer higher okRate, then discount family (Auto), then lower tokens, then higher quality
    return @($out | Sort-Object `
        @{ Expression = 'okRate'; Descending = $true }, `
        @{ Expression = 'discountBoost'; Descending = $true }, `
        medianTokens, `
        @{ Expression = 'avgQuality'; Descending = $true })
}

function Get-MatrixTaskCell {
    param(
        [string]$TaskKind = 'implement',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $m = Get-ModelMatrix -Root $Root
    if ($m.cells -and $m.cells.$TaskKind) { return $m.cells.$TaskKind }
    return [pscustomobject]@{
        start       = [pscustomobject]@{ family = 'copilot-auto'; effort = 'medium' }
        escalate    = @()
        evidenceMin = 3
        source      = 'default'
    }
}

function Get-RecommendedMatrixCell {
    param(
        [string]$TaskKind = 'implement',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cell = Get-MatrixTaskCell -TaskKind $TaskKind -Root $Root
    $ladder = Get-LadderConfig -Root $Root
    $minN = if ($cell.evidenceMin) { [int]$cell.evidenceMin } else { [int]$ladder.evidenceMin }
    if (-not $minN) { $minN = 3 }
    $prefer = if ($ladder.preferDiscountFamily) { [string]$ladder.preferDiscountFamily } else { 'copilot-auto' }

    $stats = @(Get-MatrixCellStats -TaskKind $TaskKind -Root $Root | Where-Object { $_.n -ge $minN })
    if ($stats.Count -gt 0) {
        # Among top okRate band, prefer discount family if within 0.05
        $bestRate = [double]$stats[0].okRate
        $band = @($stats | Where-Object { ([double]$_.okRate) -ge ($bestRate - 0.05) })
        $auto = $band | Where-Object { $_.family -eq $prefer } | Select-Object -First 1
        $best = if ($auto) { $auto } else { $stats[0] }
        return [pscustomobject]@{
            taskKind = $TaskKind
            family   = $best.family
            effort   = $best.effort
            source   = 'evidence'
            okRate   = $best.okRate
            n        = $best.n
            note     = if ($best.family -eq $prefer) { 'prefer-auto-discount' } else { '' }
        }
    }

    $start = $cell.start
    return [pscustomobject]@{
        taskKind = $TaskKind
        family   = $start.family
        effort   = $start.effort
        source   = if ($cell.source) { $cell.source } else { 'seed' }
        okRate   = $null
        n        = 0
        note     = 'seed-prefer-auto'
    }
}

function Test-LadderShouldEscalate {
    param(
        [ValidateSet('ok', 'warn', 'deny', 'error')][string]$Outcome = 'ok',
        [Nullable[double]]$QualityScore = $null,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $ladder = Get-LadderConfig -Root $Root
    $reasons = New-Object System.Collections.Generic.List[string]
    $on = @($ladder.escalateOn)
    if ($on.Count -eq 0) { $on = @('error', 'deny', 'qualityBelow') }

    if ($Outcome -eq 'error' -and ($on -contains 'error')) { [void]$reasons.Add('error') }
    if ($Outcome -eq 'deny' -and ($on -contains 'deny')) { [void]$reasons.Add('deny') }
    if ($Outcome -eq 'warn' -and ($on -contains 'warn')) { [void]$reasons.Add('warn') }

    $qMin = 0.75
    if ($null -ne $ladder.qualityMin) { $qMin = [double]$ladder.qualityMin }
    if (($on -contains 'qualityBelow') -and ($null -ne $QualityScore) -and ([double]$QualityScore -lt $qMin)) {
        [void]$reasons.Add('qualityBelow')
    }

    return [pscustomobject]@{
        ShouldEscalate = ($reasons.Count -gt 0)
        Reasons        = @($reasons)
        QualityMin     = $qMin
        QualityScore   = $QualityScore
        Outcome        = $Outcome
    }
}

function Get-NextLadderCell {
    param(
        [string]$TaskKind = 'implement',
        [Parameter(Mandatory)][string]$CurrentFamily,
        [Parameter(Mandatory)][string]$CurrentEffort,
        [int]$StepIndex = 0,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cell = Get-MatrixTaskCell -TaskKind $TaskKind -Root $Root
    $path = @($cell.escalate)
    if ($path.Count -eq 0) { return $null }
    if ($StepIndex -ge $path.Count) { return $null }
    $next = $path[$StepIndex]
    return [pscustomobject]@{
        family = $next.family
        effort = $next.effort
        step   = $StepIndex
    }
}

function New-LadderSynthPack {
    param(
        [Parameter(Mandatory)][string]$Query,
        [string]$AttemptSummary = '',
        [string]$WhatWorked = '',
        [string]$Blockers = '',
        [string]$Artifacts = '',
        [string]$NextAsk = '',
        [string]$FromFamily = '',
        [string]$FromEffort = '',
        [string]$ToFamily = '',
        [string]$ToEffort = '',
        [string]$TaskKind = 'implement',
        [string]$EscalateReason = '',
        [string]$RunId = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    if (-not $RunId) { $RunId = [guid]::NewGuid().ToString('n').Substring(0, 12) }
    $dir = Join-Path $Root 'evidence\ladder'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

    $pack = [ordered]@{
        type            = 'LadderSynthPack'
        runId           = $RunId
        taskKind        = $TaskKind
        query           = $Query
        attemptSummary  = $AttemptSummary
        whatWorked      = $WhatWorked
        blockers        = $Blockers
        artifacts       = $Artifacts
        nextAsk         = $NextAsk
        escalateReason  = $EscalateReason
        from            = [ordered]@{ family = $FromFamily; effort = $FromEffort }
        to              = [ordered]@{ family = $ToFamily; effort = $ToEffort }
        packedAt        = (Get-Date).ToUniversalTime().ToString('o')
    }
    $jsonPath = Join-Path $dir "$RunId.json"
    ($pack | ConvertTo-Json -Depth 6) | Set-Content $jsonPath -Encoding utf8

    $md = @(
        "# Ladder synth pack ($RunId)"
        ""
        "**Task:** $TaskKind"
        "**Reason:** $EscalateReason"
        "**From:** $FromFamily / $FromEffort -> **To:** $ToFamily / $ToEffort"
        ""
        "## Query"
        $Query
        ""
        "## Attempt summary"
        $AttemptSummary
        ""
        "## What worked"
        $WhatWorked
        ""
        "## Blockers / quality gaps"
        $Blockers
        ""
        "## Artifacts"
        $Artifacts
        ""
        "## Next ask (synthesis only - do not rediscover)"
        $NextAsk
    ) -join [Environment]::NewLine
    $mdPath = Join-Path $dir "$RunId.md"
    Set-Content -Path $mdPath -Value $md -Encoding utf8

    return [pscustomobject]@{ Pack = $pack; JsonPath = $jsonPath; MdPath = $mdPath }
}

function Invoke-LadderEscalate {
    param(
        [string]$TaskKind = 'implement',
        [Parameter(Mandatory)][string]$Query,
        [Parameter(Mandatory)][string]$CurrentFamily,
        [Parameter(Mandatory)][string]$CurrentEffort,
        [int]$StepIndex = 0,
        [ValidateSet('ok', 'warn', 'deny', 'error')][string]$Outcome = 'error',
        [Nullable[double]]$QualityScore = $null,
        [switch]$Force,
        [string]$AttemptSummary = '',
        [string]$WhatWorked = '',
        [string]$Blockers = '',
        [string]$Artifacts = '',
        [string]$NextAsk = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $ladder = Get-LadderConfig -Root $Root
    if (-not $ladder.enabled) { throw 'Ladder disabled in matrix.json' }
    if ($StepIndex -ge [int]$ladder.maxSteps) { throw "Ladder maxSteps ($($ladder.maxSteps)) exceeded" }

    $gate = Test-LadderShouldEscalate -Outcome $Outcome -QualityScore $QualityScore -Root $Root
    if (-not $Force -and -not $gate.ShouldEscalate) {
        return [pscustomobject]@{
            Escalated = $false
            Gate      = $gate
            Message   = 'No escalate: outcome/quality within gate (stay on current cell; keep Auto discount if applicable)'
        }
    }

    $next = Get-NextLadderCell -TaskKind $TaskKind -CurrentFamily $CurrentFamily -CurrentEffort $CurrentEffort -StepIndex $StepIndex -Root $Root
    if (-not $next) { throw 'No further escalate steps for taskKind' }

    $reason = if ($gate.Reasons.Count -gt 0) { ($gate.Reasons -join ',') } else { 'force' }
    $pack = New-LadderSynthPack -Query $Query -AttemptSummary $AttemptSummary -WhatWorked $WhatWorked `
        -Blockers $Blockers -Artifacts $Artifacts -NextAsk $NextAsk -EscalateReason $reason `
        -FromFamily $CurrentFamily -FromEffort $CurrentEffort `
        -ToFamily $next.family -ToEffort $next.effort -TaskKind $TaskKind -Root $Root

    Save-MatrixEvidenceRun -TaskKind $TaskKind -Family $CurrentFamily -Effort $CurrentEffort `
        -Outcome $Outcome -QualityScore $QualityScore -EscalatedFrom '' -EscalateReason $reason -Root $Root | Out-Null

    $familyTips = Get-ModelTipCard -Family $next.family -Root $Root
    $effortTips = Get-EffortTipCard -Effort $next.effort -Root $Root
    $statePath = Join-Path $Root 'memory\.model-state.json'
    $dir = Split-Path $statePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $switchHint = if ($next.family -eq 'copilot-auto') {
        "Keep model picker on Auto (10% discount); raise effort to '$($next.effort)'."
    } else {
        "Leave Auto if needed; switch family to '$($next.family)'; effort '$($next.effort)'."
    }
    @{
        family       = $next.family
        effort       = $next.effort
        task         = $TaskKind
        tips         = $familyTips
        effortTips   = $effortTips
        synthPack    = $pack.MdPath
        escalated    = $true
        reason       = $reason
        step         = $StepIndex
        injectedAt   = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json -Depth 4 | Set-Content $statePath -Encoding utf8

    return [pscustomobject]@{
        Escalated  = $true
        Gate       = $gate
        Next       = $next
        Pack       = $pack
        FamilyTips = $familyTips
        EffortTips = $effortTips
        Message    = "$switchHint Continue from synth pack only: $($pack.MdPath)"
    }
}

function Invoke-MatrixDoPrep {
    param(
        [string]$TaskKind = 'implement',
        [string]$Family = '',
        [string]$Effort = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $rec = Get-RecommendedMatrixCell -TaskKind $TaskKind -Root $Root
    if ($Family) { $rec = [pscustomobject]@{ taskKind = $TaskKind; family = $Family; effort = $(if ($Effort) { $Effort } else { $rec.effort }); source = 'override'; okRate = $null; n = 0; note = '' } }
    elseif ($Effort) { $rec = [pscustomobject]@{ taskKind = $TaskKind; family = $rec.family; effort = $Effort; source = $rec.source; okRate = $rec.okRate; n = $rec.n; note = $rec.note } }

    $familyTips = Get-ModelTipCard -Family $rec.family -Root $Root
    $effortTips = Get-EffortTipCard -Effort $rec.effort -Root $Root
    $statePath = Join-Path $Root 'memory\.model-state.json'
    $dir = Split-Path $statePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    @{
        family     = $rec.family
        effort     = $rec.effort
        task       = $TaskKind
        source     = $rec.source
        note       = $rec.note
        tips       = $familyTips
        effortTips = $effortTips
        injectedAt = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json -Depth 4 | Set-Content $statePath -Encoding utf8

    return $rec
}

Export-ModuleMember -Function Get-MatrixRunsDir, Get-LadderConfig, Get-EffortTipCard,
    Save-MatrixEvidenceRun, Get-MatrixEvidenceRuns, Get-MatrixCellStats,
    Get-MatrixTaskCell, Get-RecommendedMatrixCell, Test-LadderShouldEscalate, Get-NextLadderCell,
    New-LadderSynthPack, Invoke-LadderEscalate, Invoke-MatrixDoPrep
