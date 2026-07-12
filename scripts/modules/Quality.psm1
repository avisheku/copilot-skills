# Copilot Skills — Instruction Contract Score (ICS) quality gate (Phase 8)

function Get-QualityGateConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\evals\quality-gate.json'
    if (-not (Test-Path $path)) { throw "Quality gate config missing: $path" }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-QualityCasesPath {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'shared\fixtures\l4-quality-cases.json'
}

function Get-QualityBaselinePath {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'evidence\quality-baseline.json'
}

function Get-QualityCasesVersion {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Get-QualityCasesPath -Root $Root
    if (-not (Test-Path $path)) { throw "Quality cases missing: $path" }
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
        return ([BitConverter]::ToString($hash) -replace '-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Test-PathMatchesQualityGlobs {
    param(
        [Parameter(Mandatory)][string]$TargetPath,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-QualityGateConfig -Root $Root
    $full = [System.IO.Path]::GetFullPath($TargetPath)
    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
    $rel = $full
    if ($full.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $full.Substring($rootFull.Length).TrimStart('\', '/').Replace('\', '/')
    } else {
        $rel = $rel.Replace('\', '/')
    }
    foreach ($g in @($cfg.pathGlobs)) {
        $pattern = ($g -replace '\\', '/').Replace('**/', '*').Replace('**', '*')
        if ($rel -like $pattern) { return $true }
        # also match basename-style skills/*.md
        if ($rel -like ($g -replace '\*\*/', '*' -replace '\\', '/')) { return $true }
    }
    # explicit common targets
    if ($rel -match '^(skills/.+\.md|config/moa/.+|docs/HANDBOOK\.md|shared/instructions/.+)$') {
        return $true
    }
    return $false
}

function Test-QualityCheck {
    param(
        [Parameter(Mandatory)]$Check,
        [Parameter(Mandatory)][string]$Text,
        [long]$ByteLength
    )
    $op = [string]$Check.op
    switch ($op) {
        'contains' {
            return ($Text.IndexOf([string]$Check.value, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
        }
        'notContains' {
            return ($Text.IndexOf([string]$Check.value, [System.StringComparison]::OrdinalIgnoreCase) -lt 0)
        }
        'heading' {
            $h = [string]$Check.value
            return ($Text -match "(?m)^#{1,3}\s+$([regex]::Escape($h))\s*$") -or
                   ($Text.IndexOf("## $h", [System.StringComparison]::OrdinalIgnoreCase) -ge 0) -or
                   ($Text.IndexOf("# $h", [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
        }
        'verifyBlock' {
            return ($Text -match '(?m)^VERIFY:')
        }
        'minBytes' {
            return ($ByteLength -ge [long]$Check.value)
        }
        'maxBytes' {
            return ($ByteLength -le [long]$Check.value)
        }
        default {
            return $false
        }
    }
}

function Invoke-InstructionQualitySuite {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $casesPath = Get-QualityCasesPath -Root $Root
    if (-not (Test-Path $casesPath)) {
        return [pscustomobject]@{
            Pass = $false; Score = 0; CasesVersion = $null
            Issues = @("cases missing: $casesPath"); CaseResults = @()
        }
    }
    $spec = Get-Content $casesPath -Raw | ConvertFrom-Json
    $casesVersion = Get-QualityCasesVersion -Root $Root
    $caseResults = [System.Collections.Generic.List[object]]::new()
    $weightSum = 0.0
    $passWeight = 0.0
    $issues = [System.Collections.Generic.List[string]]::new()

    foreach ($case in @($spec.cases)) {
        $w = [double]$(if ($case.weight) { $case.weight } else { 1 })
        $weightSum += $w
        $texts = @()
        $bytes = 0L
        $missing = @()
        foreach ($p in @($case.paths)) {
            $fp = Join-Path $Root ($p -replace '/', '\')
            if (-not (Test-Path $fp)) { $missing += $p; continue }
            $raw = Get-Content $fp -Raw -ErrorAction SilentlyContinue
            if ($null -eq $raw) { $raw = '' }
            $texts += $raw
            $bytes += (Get-Item $fp).Length
        }
        $combined = ($texts -join "`n")
        $failedChecks = @()
        if ($missing.Count -gt 0) {
            $failedChecks += "missing paths: $($missing -join ', ')"
        } else {
            foreach ($chk in @($case.checks)) {
                if (-not (Test-QualityCheck -Check $chk -Text $combined -ByteLength $bytes)) {
                    $failedChecks += "$($chk.op):$($chk.value)"
                }
            }
        }
        $ok = ($failedChecks.Count -eq 0)
        if ($ok) { $passWeight += $w }
        else {
            $issues.Add("$($case.id): $($failedChecks -join '; ')")
        }
        $caseResults.Add([ordered]@{
            id     = $case.id
            weight = $w
            pass   = $ok
            failed = $failedChecks
        }) | Out-Null
    }

    $score = if ($weightSum -gt 0) { [math]::Round($passWeight / $weightSum, 4) } else { 0 }
    [pscustomobject]@{
        Pass         = ($issues.Count -eq 0)
        Score        = $score
        CasesVersion = $casesVersion
        Issues       = @($issues)
        CaseResults  = @($caseResults)
        WeightSum    = $weightSum
        PassWeight   = $passWeight
    }
}

function Compare-QualityToBaseline {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        $Suite = $null
    )
    $cfg = Get-QualityGateConfig -Root $Root
    if ($null -eq $Suite) {
        $Suite = Invoke-InstructionQualitySuite -Root $Root
    }
    $baselinePath = Get-QualityBaselinePath -Root $Root
    $issues = [System.Collections.Generic.List[string]]::new()
    $minAbs = [double]$cfg.minAbsolute
    $maxDrop = [double]$cfg.maxDropFromBaseline

    if ($Suite.Score -lt $minAbs) {
        $issues.Add("score $($Suite.Score) < minAbsolute $minAbs")
    }

    if (-not (Test-Path $baselinePath)) {
        $issues.Add("baseline missing: $baselinePath - run Update-QualityBaseline.ps1")
        return [pscustomobject]@{
            Pass = $false; Score = $Suite.Score; Baseline = $null
            Drop = $null; Issues = @($issues); Suite = $Suite
        }
    }

    $baseline = Get-Content $baselinePath -Raw | ConvertFrom-Json
    if ([string]$baseline.casesVersion -ne [string]$Suite.CasesVersion) {
        $issues.Add("casesVersion mismatch - rebuild baseline with Update-QualityBaseline.ps1")
    }

    $baseScore = [double]$baseline.score
    $drop = [math]::Round($baseScore - [double]$Suite.Score, 4)
    if ($drop -gt $maxDrop) {
        $issues.Add("drop $drop > maxDropFromBaseline $maxDrop (baseline $baseScore -> $($Suite.Score))")
    }

    # surface case-level failures too
    foreach ($i in @($Suite.Issues)) { $issues.Add($i) }

    [pscustomobject]@{
        Pass     = ($issues.Count -eq 0)
        Score    = $Suite.Score
        Baseline = $baseScore
        Drop     = $drop
        Issues   = @($issues | Select-Object -Unique)
        Suite    = $Suite
    }
}

function Invoke-QualityGate {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [string]$TargetPath
    )
    if ($TargetPath) {
        if (-not (Test-PathMatchesQualityGlobs -TargetPath $TargetPath -Root $Root)) {
            return [pscustomobject]@{ Pass = $true; Skipped = $true; Issues = @('path not in quality globs') }
        }
    }
    $cmp = Compare-QualityToBaseline -Root $Root
    [pscustomobject]@{
        Pass     = $cmp.Pass
        Skipped  = $false
        Score    = $cmp.Score
        Baseline = $cmp.Baseline
        Drop     = $cmp.Drop
        Issues   = $cmp.Issues
    }
}

function Save-QualityBaseline {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $suite = Invoke-InstructionQualitySuite -Root $Root
    if (-not $suite.Pass -or $suite.Score -lt (Get-QualityGateConfig -Root $Root).minAbsolute) {
        throw "Refusing baseline: suite not green (score=$($suite.Score) issues=$($suite.Issues -join '; '))"
    }
    $caseScores = @{}
    foreach ($c in @($suite.CaseResults)) {
        $caseScores[$c.id] = @{ pass = [bool]$c.pass; weight = $c.weight }
    }
    $obj = [ordered]@{
        version      = 1
        casesVersion = $suite.CasesVersion
        score        = $suite.Score
        caseScores   = $caseScores
        generatedAt  = (Get-Date).ToUniversalTime().ToString('o')
        note         = 'Instruction Contract Score (deterministic). Update only after intentional green upgrades.'
    }
    $path = Get-QualityBaselinePath -Root $Root
    $dir = Split-Path $path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $obj | ConvertTo-Json -Depth 6 | Set-Content $path -Encoding utf8
    return $path
}

Export-ModuleMember -Function Get-QualityGateConfig, Get-QualityCasesVersion, Test-PathMatchesQualityGlobs,
    Invoke-InstructionQualitySuite, Compare-QualityToBaseline, Invoke-QualityGate, Save-QualityBaseline,
    Get-QualityBaselinePath, Get-QualityCasesPath
