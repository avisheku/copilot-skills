# SkillsForge — context compaction (Pillar 3 thrift)
# Compresses OUR working memory / evidence dumps. Does NOT fake IDE chat compact APIs
# (ADR O4: harness may compact chat; we handoff/compact artifacts on ask or threshold).
# Get-TextBudget lives in Budget.psm1 (loaded first).

function Get-ContextCompactPolicy {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $policy = Get-SessionPolicy -Root $Root
    $c = $policy.contextCompact
    if (-not $c) {
        return [pscustomobject]@{
            enabled           = $true
            askBeforeCompact  = $true
            maxPackChars      = 3500
            maxGoalChars      = 500
            maxStepChars      = 200
            maxStepsListed    = 12
            maxLedgerTail     = 15
            maxOpenQuestions  = 5
            keepLadderPacks   = 3
            keepMatrixRuns    = 50
            softWarnBytes     = 200000
            onSoftWarn        = 'compact'
            onHardStop        = 'handoff'
        }
    }
    return $c
}

function Measure-ContextWeight {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $paths = @(
        (Join-Path $Root 'memory\.context-state.json'),
        (Join-Path $Root 'memory\.model-state.json'),
        (Join-Path $Root 'memory\.handoff-pack.json'),
        (Join-Path $Root 'memory\.context-compact.json'),
        (Join-Path $Root 'memory\.context-compact.md')
    )
    $bytes = 0L
    $files = 0
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $bytes += (Get-Item $p).Length
            $files++
        }
    }
    $ladderDir = Join-Path $Root 'evidence\ladder'
    $ladderN = 0
    if (Test-Path $ladderDir) {
        $ladderFiles = @(Get-ChildItem $ladderDir -File -ErrorAction SilentlyContinue)
        $ladderN = $ladderFiles.Count
        foreach ($f in $ladderFiles) { $bytes += $f.Length }
    }
    $tokenEst = Get-SessionTokenEstimate -Root $Root
    if ($null -eq $tokenEst) { $tokenEst = 0 }
    $thresh = Test-SessionTokenThreshold -Root $Root
    $cpol = Get-ContextCompactPolicy -Root $Root
    $softBytes = 200000
    if ($null -ne $cpol.softWarnBytes) { $softBytes = [int]$cpol.softWarnBytes }
    return [pscustomobject]@{
        ArtifactBytes = [long]$bytes
        ArtifactFiles = $files
        LadderFiles   = $ladderN
        TokenEstimate = [long]$tokenEst
        SoftWarn      = [bool]$thresh.Warn
        HardStop      = [bool]$thresh.Stop
        Heavy         = ([long]$bytes -ge $softBytes) -or [bool]$thresh.Warn
        SoftWarnBytes = $softBytes
    }
}

function Test-ShouldCompact {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $pol = Get-ContextCompactPolicy -Root $Root
    if (-not $pol.enabled) {
        return [pscustomobject]@{ Should = $false; Reason = 'disabled'; Weight = (Measure-ContextWeight -Root $Root) }
    }
    $w = Measure-ContextWeight -Root $Root
    $reasons = New-Object System.Collections.Generic.List[string]
    if ($w.HardStop) { [void]$reasons.Add('tokenHardStop') }
    if ($w.SoftWarn) { [void]$reasons.Add('tokenSoftWarn') }
    if ($w.Heavy -and -not $w.SoftWarn) { [void]$reasons.Add('artifactHeavy') }
    return [pscustomobject]@{
        Should = ($reasons.Count -gt 0)
        Reason = ($reasons -join ',')
        Weight = $w
        AskFirst = [bool]$pol.askBeforeCompact
        OnSoft   = "$($pol.onSoftWarn)"
        OnHard   = "$($pol.onHardStop)"
    }
}

function Clear-StaleEvidenceArtifacts {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $pol = Get-ContextCompactPolicy -Root $Root
    $removed = New-Object System.Collections.Generic.List[string]

    $keepLadder = 3
    if ($null -ne $pol.keepLadderPacks) { $keepLadder = [int]$pol.keepLadderPacks }
    $ladderDir = Join-Path $Root 'evidence\ladder'
    if (Test-Path $ladderDir) {
        $groups = @(Get-ChildItem $ladderDir -File | Group-Object { [IO.Path]::GetFileNameWithoutExtension($_.Name) } |
            Sort-Object { ($_.Group | Measure-Object LastWriteTime -Maximum).Maximum } -Descending)
        if ($groups.Count -gt $keepLadder) {
            foreach ($g in $groups[$keepLadder..($groups.Count - 1)]) {
                foreach ($f in $g.Group) {
                    Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
                    [void]$removed.Add($f.FullName)
                }
            }
        }
    }

    $keepRuns = 50
    if ($null -ne $pol.keepMatrixRuns) { $keepRuns = [int]$pol.keepMatrixRuns }
    $runsDir = Join-Path $Root 'evidence\matrix\runs'
    if (Test-Path $runsDir) {
        $runs = @(Get-ChildItem $runsDir -Filter '*.json' | Sort-Object LastWriteTime -Descending)
        if ($runs.Count -gt $keepRuns) {
            foreach ($f in $runs[$keepRuns..($runs.Count - 1)]) {
                Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
                [void]$removed.Add($f.FullName)
            }
        }
    }

    return [pscustomobject]@{ Removed = @($removed); KeepLadder = $keepLadder; KeepMatrixRuns = $keepRuns }
}

function New-ContextCompactPack {
    param(
        [string]$Goal = '',
        [string[]]$CompletedSteps = @(),
        [string[]]$RemainingSteps = @(),
        [string[]]$OpenQuestions = @(),
        [string]$Blockers = '',
        [string]$NextAsk = '',
        [string]$TaskKind = 'implement',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $pol = Get-ContextCompactPolicy -Root $Root
    $maxGoal = 500; if ($null -ne $pol.maxGoalChars) { $maxGoal = [int]$pol.maxGoalChars }
    $maxStep = 200; if ($null -ne $pol.maxStepChars) { $maxStep = [int]$pol.maxStepChars }
    $maxListed = 12; if ($null -ne $pol.maxStepsListed) { $maxListed = [int]$pol.maxStepsListed }
    $maxQ = 5; if ($null -ne $pol.maxOpenQuestions) { $maxQ = [int]$pol.maxOpenQuestions }
    $maxPack = 3500; if ($null -ne $pol.maxPackChars) { $maxPack = [int]$pol.maxPackChars }
    $ledgerTail = 15; if ($null -ne $pol.maxLedgerTail) { $ledgerTail = [int]$pol.maxLedgerTail }

    $rec = Get-RecommendedMatrixCell -TaskKind $TaskKind -Root $Root
    $thresh = Test-SessionTokenThreshold -Root $Root
    $completed = @($CompletedSteps | Select-Object -First $maxListed | ForEach-Object { Get-TextBudget -Text "$_" -MaxChars $maxStep })
    $remaining = @($RemainingSteps | Select-Object -First $maxListed | ForEach-Object { Get-TextBudget -Text "$_" -MaxChars $maxStep })
    $questions = @($OpenQuestions | Select-Object -First $maxQ | ForEach-Object { Get-TextBudget -Text "$_" -MaxChars $maxStep })

    $ledgerBrief = @()
    try {
        $entries = @(Get-LedgerEntries -Root $Root -Tail $ledgerTail)
        foreach ($e in $entries) {
            $ledgerBrief += ('{0}/{1}:{2}' -f $e.skill, $e.tool, $e.outcome)
        }
    } catch { }

    $pack = [ordered]@{
        type           = 'ContextCompactPack'
        goal           = (Get-TextBudget -Text $Goal -MaxChars $maxGoal)
        taskKind       = $TaskKind
        completedSteps = $completed
        remainingSteps = $remaining
        openQuestions  = $questions
        blockers       = (Get-TextBudget -Text $Blockers -MaxChars 400)
        nextAsk        = (Get-TextBudget -Text $NextAsk -MaxChars 400)
        matrix         = @{
            family = $rec.family
            effort = $rec.effort
            source = $rec.source
        }
        tokens         = @{
            estimate = $thresh.Estimate
            softWarn = $thresh.SoftWarn
            hardStop = $thresh.HardStop
            warn     = $thresh.Warn
            stop     = $thresh.Stop
        }
        ledgerBrief    = $ledgerBrief
        instruction    = 'Continue from this pack only. Do not re-read full chat or dump prior tips/evidence into context.'
        createdAt      = (Get-Date).ToUniversalTime().ToString('o')
    }

    $json = ($pack | ConvertTo-Json -Depth 6 -Compress)
    if ($json.Length -gt $maxPack) {
        $pack.ledgerBrief = @($ledgerBrief | Select-Object -Last 5)
        $pack.completedSteps = @($completed | Select-Object -First 6)
        $json = ($pack | ConvertTo-Json -Depth 6 -Compress)
        if ($json.Length -gt $maxPack) {
            $json = Get-TextBudget -Text $json -MaxChars $maxPack
        }
    }

    $dir = Join-Path $Root 'memory'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $jsonPath = Join-Path $dir '.context-compact.json'
    $mdPath = Join-Path $dir '.context-compact.md'
    Set-Content -Path $jsonPath -Value $json -Encoding utf8

    $md = @(
        '# Context compact pack'
        ''
        "**Goal:** $($pack.goal)"
        "**Task:** $TaskKind · **Matrix:** $($rec.family)/$($rec.effort)"
        "**Tokens est:** $($thresh.Estimate) (soft $($thresh.SoftWarn) / hard $($thresh.HardStop))"
        ''
        '## Done'
    ) + @($completed | ForEach-Object { "- $_" }) + @(
        ''
        '## Remaining'
    ) + @($remaining | ForEach-Object { "- $_" }) + @(
        ''
        '## Blockers'
        $pack.blockers
        ''
        '## Next ask (do not rediscover)'
        $pack.nextAsk
        ''
        '_Continue from this pack only._'
    )
    $mdText = Get-TextBudget -Text ($md -join [Environment]::NewLine) -MaxChars $maxPack
    Set-Content -Path $mdPath -Value $mdText -Encoding utf8

    return [pscustomobject]@{
        Pack     = $pack
        JsonPath = $jsonPath
        MdPath   = $mdPath
        Chars    = $json.Length
    }
}

function Invoke-ContextCompact {
    param(
        [string]$Goal = 'continue session',
        [string[]]$CompletedSteps = @(),
        [string[]]$RemainingSteps = @(),
        [string[]]$OpenQuestions = @(),
        [string]$Blockers = '',
        [string]$NextAsk = '',
        [string]$TaskKind = 'implement',
        [switch]$SkipAsk,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $gate = Test-ShouldCompact -Root $Root

    $pack = New-ContextCompactPack -Goal $Goal -CompletedSteps $CompletedSteps -RemainingSteps $RemainingSteps `
        -OpenQuestions $OpenQuestions -Blockers $Blockers -NextAsk $NextAsk -TaskKind $TaskKind -Root $Root

    Restore-ContextDefault -Root $Root | Out-Null

    $statePath = Join-Path $Root 'memory\.model-state.json'
    if (Test-Path $statePath) {
        try {
            $st = Get-Content $statePath -Raw | ConvertFrom-Json
            $slim = [ordered]@{
                family      = $st.family
                effort      = $st.effort
                task        = $st.task
                tipCard     = if ($st.tipCard) { $st.tipCard } else { "config/models/tips/$($st.family).md" }
                effortCard  = if ($st.effortCard) { $st.effortCard } else { "config/models/efforts/$($st.effort).md" }
                compactRef  = $pack.MdPath
                compactedAt = (Get-Date).ToUniversalTime().ToString('o')
            }
            ($slim | ConvertTo-Json -Depth 4) | Set-Content $statePath -Encoding utf8
        } catch { }
    }

    $prune = Clear-StaleEvidenceArtifacts -Root $Root
    Write-LedgerEntry -Skill 'context' -Tool 'compact' -Outcome 'ok' -Root $Root | Out-Null

    return [pscustomobject]@{
        Compacted = $true
        Pack      = $pack
        Prune     = $prune
        Gate      = $gate
        SkipAsk   = [bool]$SkipAsk
        Message   = "Context compacted to $($pack.MdPath). Continue from pack only; do not rehydrate full history."
    }
}

Export-ModuleMember -Function Get-ContextCompactPolicy, Measure-ContextWeight,
    Test-ShouldCompact, Clear-StaleEvidenceArtifacts, New-ContextCompactPack, Invoke-ContextCompact
