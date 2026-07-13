# Copilot Skills — upgrade-only learn + error-map

function Get-LearnConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-PackConfig -Name 'learn.json' -Root $Root
}

function Get-ErrorMapDir {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'learn\error-map'
}

function New-ErrorMapEntry {
    param(
        [string]$Id,
        [string]$Symptom,
        [string]$RootCause,
        [string]$Fix,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $dir = Get-ErrorMapDir -Root $Root
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $entry = [ordered]@{
        id         = $Id
        symptom    = $Symptom
        rootCause  = $RootCause
        fix        = $Fix
        createdAt  = (Get-Date).ToUniversalTime().ToString('o')
        version    = 1
    }
    $path = Join-Path $dir "$Id.json"
    $entry | ConvertTo-Json -Depth 3 | Set-Content $path -Encoding utf8
    return $entry
}

function Get-ErrorMapEntries {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $dir = Get-ErrorMapDir -Root $Root
    if (-not (Test-Path $dir)) { return @() }
    Get-ChildItem $dir -Filter '*.json' | ForEach-Object {
        Get-Content $_.FullName -Raw | ConvertFrom-Json
    }
}

function Get-LearnStagingPath {
    param([string]$Kind, [string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root "share\learnings\$Kind"
}

function New-LearnStaging {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$Title,
        [string]$Body,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-LearnConfig -Root $Root
    if ($cfg.kinds -notcontains $Kind) { throw "Unknown learn kind: $Kind" }
    $dir = Get-LearnStagingPath -Kind $Kind -Root $Root
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $id = [guid]::NewGuid().ToString('n').Substring(0, 8)
    $staging = [ordered]@{
        id        = $id
        kind      = $Kind
        title     = $Title
        body      = $Body
        status    = 'staging'
        createdAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    $path = Join-Path $dir "$id.json"
    $staging | ConvertTo-Json -Depth 3 | Set-Content $path -Encoding utf8
    return $staging
}

function Test-LearnUpgradeOnly {
    param(
        [string]$StagingPath,
        [string]$TargetPath,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $issues = @()
    if (-not (Test-Path $StagingPath)) { return [pscustomobject]@{ Pass = $false; Issues = @('staging missing') } }
    if (Test-Path $TargetPath) {
        $old = (Get-Item $TargetPath).Length
        $new = (Get-Item $StagingPath).Length
        if ($new -lt ($old * 0.5) -and $old -gt 100) {
            $issues += 'possible degrade: staging much smaller than target'
        }
        # Markdown targets: required headings / VERIFY markers must not disappear
        if ($TargetPath -match '\.(md|markdown)$') {
            $before = Get-Content $TargetPath -Raw -ErrorAction SilentlyContinue
            $after = Get-Content $StagingPath -Raw -ErrorAction SilentlyContinue
            if ($before -and $after) {
                $markers = Test-MarkersPreserved -BeforeText $before -AfterText $after
                if (-not $markers.Pass) {
                    $issues += "markers dropped: $($markers.Missing -join '; ')"
                }
            }
        }
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = $issues }
}

function Invoke-LearnPromote {
    param(
        [Parameter(Mandatory)][string]$StagingFile,
        [Parameter(Mandatory)][string]$TargetFile,
        [switch]$DualSync,
        [switch]$SkipPromoteGates,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-LearnConfig -Root $Root
    if (-not $cfg.upgradeOnly) { throw 'upgradeOnly disabled' }

    if (-not $SkipPromoteGates) {
        $gate = Invoke-L2PromoteGate -Root $Root
        if (-not $gate.Pass) { throw "Promote gate failed: $($gate.Issues -join '; ')" }
        $qg = Invoke-QualityGate -Root $Root -TargetPath $TargetFile
        if (-not $qg.Pass) { throw "Quality gate failed: $($qg.Issues -join '; ')" }
    }

    $upgrade = Test-LearnUpgradeOnly -StagingPath $StagingFile -TargetPath $TargetFile -Root $Root
    if (-not $upgrade.Pass) { throw "Upgrade check failed: $($upgrade.Issues -join '; ')" }

    $targetDir = Split-Path $TargetFile -Parent
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
    Copy-Item $StagingFile $TargetFile -Force

    if ($DualSync) {
        Sync-CopilotSkillsTarget -Target Copilot -Root $Root | Out-Null
    }
    Write-LedgerEntry -Skill 'learn' -Tool 'promote' -Outcome 'ok' -Root $Root | Out-Null
    return [pscustomobject]@{ Promoted = $TargetFile; DualSync = [bool]$DualSync }
}

function Invoke-LearnHandbookPatch {
    param(
        [Parameter(Mandatory)][string]$StagingFile,
        [switch]$WhatIf,
        [switch]$SkipPromoteGates,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $handbook = Join-Path $Root 'docs\HANDBOOK.md'
    if (-not (Test-Path $handbook)) { throw 'HANDBOOK.md not found' }
    $hbBefore = Get-Content $handbook -Raw
    if ($hbBefore -notmatch 'VERIFY:') { throw 'Handbook VERIFY blocks must remain intact' }

    if (-not $SkipPromoteGates) {
        $gate = Invoke-L2PromoteGate -Root $Root
        if (-not $gate.Pass) { throw "Promote gate failed: $($gate.Issues -join '; ')" }
        $qg = Invoke-QualityGate -Root $Root -TargetPath $handbook
        if (-not $qg.Pass) { throw "Quality gate failed: $($qg.Issues -join '; ')" }
    }

    $upgrade = Test-LearnUpgradeOnly -StagingPath $StagingFile -TargetPath $handbook -Root $Root
    if (-not $upgrade.Pass) { throw "Handbook patch rejected: $($upgrade.Issues -join '; ')" }

    $hbAfter = Get-Content $StagingFile -Raw
    $intact = Test-HandbookVerifyIntact -BeforeText $hbBefore -AfterText $hbAfter
    if (-not $intact.Pass) {
        throw "Handbook VERIFY/ON_FAIL regression: $($intact.Missing -join '; ')"
    }

    if (-not $WhatIf) {
        Copy-Item $StagingFile $handbook -Force
        $shareDir = Join-Path $Root 'share\handbook'
        if (-not (Test-Path $shareDir)) { New-Item -ItemType Directory -Force -Path $shareDir | Out-Null }
        Copy-Item $StagingFile (Join-Path $shareDir 'HANDBOOK.md') -Force
    }
    return @{ Patched = -not $WhatIf; Target = $handbook }
}

function New-MatrixCellProposal {
    param(
        [Parameter(Mandatory)][string]$TaskKind,
        [Parameter(Mandatory)][string]$Family,
        [ValidateSet('low', 'medium', 'high', 'extra')][string]$Effort = 'medium',
        [string]$Title = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    if (-not $Title) { $Title = "matrix start $TaskKind -> $Family/$Effort" }
    $body = (@{
        taskKind = $TaskKind
        start    = @{ family = $Family; effort = $Effort }
    } | ConvertTo-Json -Compress)
    return New-LearnStaging -Kind 'matrix-cell' -Title $Title -Body $body -Root $Root
}

function Test-MatrixCellPromoteGate {
    param(
        [Parameter(Mandatory)][string]$TaskKind,
        [Parameter(Mandatory)][string]$Family,
        [Parameter(Mandatory)][string]$Effort,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $issues = @()
    $cell = Get-MatrixTaskCell -TaskKind $TaskKind -Root $Root
    $minN = if ($cell.evidenceMin) { [int]$cell.evidenceMin } else { 3 }
    $qMin = Get-TaskQualityMin -TaskKind $TaskKind -Root $Root
    $stats = @(Get-MatrixCellStats -TaskKind $TaskKind -Root $Root)
    $candidate = $stats | Where-Object { $_.family -eq $Family -and $_.effort -eq $Effort } | Select-Object -First 1
    if (-not $candidate) {
        return [pscustomobject]@{ Pass = $false; Issues = @('no evidence for proposed cell') }
    }
    if ($candidate.n -lt $minN) {
        $issues += "need n>=$minN (got $($candidate.n))"
    }
    if ($null -ne $candidate.avgQuality -and [double]$candidate.avgQuality -lt $qMin) {
        $issues += "avgQuality $($candidate.avgQuality) < qualityMin $qMin"
    }
    $curFam = $cell.start.family
    $curEff = $cell.start.effort
    $current = $stats | Where-Object { $_.family -eq $curFam -and $_.effort -eq $curEff } | Select-Object -First 1
    $curRate = if ($current) { [double]$current.okRate } else { 0 }
    if ([double]$candidate.okRate -le $curRate -and $current) {
        if ([double]$candidate.okRate -eq $curRate -and $candidate.medianTokens -lt $current.medianTokens) {
            # ok — same rate, cheaper
        }
        elseif ($null -ne $candidate.avgQuality -and $null -ne $current.avgQuality -and
                [double]$candidate.avgQuality -gt [double]$current.avgQuality -and
                [double]$candidate.okRate -ge $curRate) {
            # ok — quality win at >= okRate
        }
        else {
            $issues += "okRate $($candidate.okRate) not better than current $curRate"
        }
    }
    if ($Family -eq $curFam -and $Effort -eq $curEff) {
        $issues += 'proposed start equals current start'
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = $issues; Candidate = $candidate; Current = $current; QualityMin = $qMin }
}

function Invoke-MatrixCellPromote {
    param(
        [Parameter(Mandatory)][string]$StagingFile,
        [switch]$SkipEvidenceGate,
        [switch]$SkipPromoteGates,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-LearnConfig -Root $Root
    if (-not $cfg.upgradeOnly) { throw 'upgradeOnly disabled' }
    if (-not (Test-Path $StagingFile)) { throw "staging missing: $StagingFile" }

    $staging = Get-Content $StagingFile -Raw | ConvertFrom-Json
    if ($staging.kind -ne 'matrix-cell') { throw 'staging kind must be matrix-cell' }
    $payload = $staging.body | ConvertFrom-Json
    $taskKind = $payload.taskKind
    $family = $payload.start.family
    $effort = $payload.start.effort
    if (-not $taskKind -or -not $family -or -not $effort) { throw 'matrix-cell body needs taskKind and start.family/effort' }

    if (-not $SkipEvidenceGate) {
        $gate = Test-MatrixCellPromoteGate -TaskKind $taskKind -Family $family -Effort $effort -Root $Root
        if (-not $gate.Pass) { throw "Matrix promote gate failed: $($gate.Issues -join '; ')" }
    }

    $matrixPath = Join-Path $Root 'config\models\matrix.json'
    # Constitution: same promote gates as handbook/md learn (L2 + ICS on matrix path)
    if (-not $SkipPromoteGates) {
        $l2 = Invoke-L2PromoteGate -Root $Root
        if (-not $l2.Pass) { throw "Promote gate failed: $($l2.Issues -join '; ')" }
        $qg = Invoke-QualityGate -Root $Root -TargetPath $matrixPath
        if (-not $qg.Pass) { throw "Quality gate failed: $($qg.Issues -join '; ')" }
    }

    $matrix = Get-Content $matrixPath -Raw | ConvertFrom-Json
    if (-not $matrix.cells.$taskKind) {
        throw "taskKind not in matrix cells: $taskKind"
    }
    $matrix.cells.$taskKind.start.family = $family
    $matrix.cells.$taskKind.start.effort = $effort
    $matrix.cells.$taskKind.source = 'learn'
    $matrix.cells.$taskKind.updatedAt = (Get-Date).ToUniversalTime().ToString('o')

    $json = $matrix | ConvertTo-Json -Depth 10
    Set-Content -Path $matrixPath -Value $json -Encoding utf8
    Write-LedgerEntry -Skill 'learn' -Tool 'promote-matrix-cell' -Outcome 'ok' -Root $Root | Out-Null
    return [pscustomobject]@{
        Promoted = $matrixPath
        TaskKind = $taskKind
        Start    = @{ family = $family; effort = $effort }
        Gates    = 'L2+ICS+evidence'
    }
}

Export-ModuleMember -Function Get-LearnConfig, New-ErrorMapEntry, Get-ErrorMapEntries,
    New-LearnStaging, Test-LearnUpgradeOnly, Invoke-LearnPromote, Invoke-LearnHandbookPatch,
    New-MatrixCellProposal, Test-MatrixCellPromoteGate, Invoke-MatrixCellPromote
