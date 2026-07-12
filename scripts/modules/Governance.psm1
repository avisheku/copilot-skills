# Copilot Skills — Phase 7 governance (markers, L2 fixtures, golden shape, promote gate)

function Get-ContractMarkers {
    param([Parameter(Mandatory)][string]$Text)
    $markers = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Text -split "`r?`n")) {
        $t = $line.Trim()
        if ($t -match '^(#{1,3}\s+.+)$') { $markers.Add($Matches[1].Trim()) | Out-Null }
        elseif ($t -match '^(VERIFY:|ON_FAIL:)\s*(.*)$') {
            $markers.Add(("$($Matches[1]) $($Matches[2])").Trim()) | Out-Null
        }
    }
    @($markers | Select-Object -Unique)
}

function Test-MarkersPreserved {
    param(
        [Parameter(Mandatory)][string]$BeforeText,
        [Parameter(Mandatory)][string]$AfterText
    )
    $before = Get-ContractMarkers -Text $BeforeText
    $missing = @()
    foreach ($m in $before) {
        if ($AfterText.IndexOf($m, [System.StringComparison]::Ordinal) -lt 0) { $missing += $m }
    }
    [pscustomobject]@{
        Pass    = ($missing.Count -eq 0)
        Before  = $before.Count
        Missing = $missing
    }
}

function Test-HandbookVerifyIntact {
    param(
        [Parameter(Mandatory)][string]$BeforeText,
        [Parameter(Mandatory)][string]$AfterText
    )
    $beforeVerify = @([regex]::Matches($BeforeText, '(?m)^VERIFY:\s*.*$') | ForEach-Object { $_.Value.Trim() } | Select-Object -Unique)
    $beforeOnFail = @([regex]::Matches($BeforeText, '(?m)^ON_FAIL:\s*.*$') | ForEach-Object { $_.Value.Trim() } | Select-Object -Unique)
    $missing = @()
    foreach ($m in ($beforeVerify + $beforeOnFail)) {
        if ($AfterText.IndexOf($m, [System.StringComparison]::Ordinal) -lt 0) { $missing += $m }
    }
    if ($AfterText -notmatch '(?m)^VERIFY:') { $missing += 'VERIFY: (any)' }
    [pscustomobject]@{
        Pass           = ($missing.Count -eq 0)
        VerifyBefore   = $beforeVerify.Count
        OnFailBefore   = $beforeOnFail.Count
        Missing        = $missing
    }
}

function Test-GoldenPathShape {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $shapePath = Join-Path $Root 'shared\fixtures\golden-path.shape.json'
    $evidencePath = Join-Path $Root 'evidence\golden-path.json'
    if (-not (Test-Path $shapePath)) {
        return [pscustomobject]@{ Pass = $false; Issues = @('shape fixture missing') }
    }
    if (-not (Test-Path $evidencePath)) {
        return [pscustomobject]@{ Pass = $false; Issues = @('golden-path evidence missing — run Test-GoldenPath first') }
    }
    $shape = Get-Content $shapePath -Raw | ConvertFrom-Json
    $ev = Get-Content $evidencePath -Raw | ConvertFrom-Json
    $issues = [System.Collections.Generic.List[string]]::new()
    if (-not $ev.pass) { $issues.Add('evidence.pass is false') }
    $steps = @($ev.steps)
    if ($steps.Count -lt [int]$shape.minSteps) {
        $issues.Add("steps $($steps.Count) < minSteps $($shape.minSteps)")
    }
    foreach ($req in @($shape.requiredSteps)) {
        $hit = $steps | Where-Object { [int]$_.step -eq [int]$req.step }
        if (-not $hit) { $issues.Add("missing step $($req.step)"); continue }
        if ($req.command -and ($hit.command -notlike "*$($req.command)*")) {
            $issues.Add("step $($req.step) command want *$($req.command)* got $($hit.command)")
        }
        if ($req.mustPass -and -not $hit.pass) {
            $issues.Add("step $($req.step) must pass")
        }
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = @($issues) }
}

function Invoke-L2FixtureSuite {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $issues = [System.Collections.Generic.List[string]]::new()
    $dir = Join-Path $Root 'shared\fixtures'
    $files = @(Get-ChildItem $dir -Filter 'l2-*.json' -ErrorAction SilentlyContinue)
    if ($files.Count -lt 1) { $issues.Add('no l2-*.json fixtures') }

    foreach ($f in $files) {
        $fx = Get-Content $f.FullName -Raw | ConvertFrom-Json
        if ($fx.type -eq 'json-path') {
            $path = Join-Path $Root $fx.path
            if (-not (Test-Path $path)) { $issues.Add("$($f.Name): missing $($fx.path)"); continue }
            $obj = Get-Content $path -Raw | ConvertFrom-Json
            foreach ($assert in @($fx.asserts)) {
                $val = $obj
                foreach ($part in ($assert.key -split '\.')) {
                    if ($null -eq $val) { break }
                    $val = $val.$part
                }
                if ($assert.op -eq 'exists' -and $null -eq $val) {
                    $issues.Add("$($f.Name): $($assert.key) missing")
                }
                elseif ($assert.op -eq 'eq' -and "$val" -ne "$($assert.value)") {
                    $issues.Add("$($f.Name): $($assert.key) want $($assert.value) got $val")
                }
                elseif ($assert.op -eq 'gte') {
                    $n = 0
                    if ($val -is [System.Array] -or $val -is [System.Collections.ICollection]) {
                        $n = @($val).Count
                    } elseif ($null -ne $val) { $n = [int]$val }
                    if ($n -lt [int]$assert.value) {
                        $issues.Add("$($f.Name): $($assert.key) count $n < $($assert.value)")
                    }
                }
                elseif ($assert.op -eq 'contains') {
                    $list = @($val)
                    if ($list -notcontains $assert.value) {
                        $issues.Add("$($f.Name): $($assert.key) missing $($assert.value)")
                    }
                }
            }
        }
        elseif ($fx.type -eq 'file-contains') {
            $path = Join-Path $Root $fx.path
            if (-not (Test-Path $path)) { $issues.Add("$($f.Name): missing $($fx.path)"); continue }
            $text = Get-Content $path -Raw
            foreach ($needle in @($fx.mustContain)) {
                if ($text.IndexOf([string]$needle, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                    $issues.Add("$($f.Name): missing marker '$needle' in $($fx.path)")
                }
            }
        }
    }

    # delegatesTo fixture still required
    $del = Join-Path $Root 'shared\fixtures\delegatesTo-research.json'
    if (-not (Test-Path $del)) { $issues.Add('delegatesTo-research.json missing') }

    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = @($issues); FixtureCount = $files.Count }
}

function Test-L3StaticMarkers {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'shared\fixtures\l3-static-markers.json'
    if (-not (Test-Path $path)) {
        return [pscustomobject]@{ Pass = $false; Issues = @('l3-static-markers.json missing'); Checked = 0 }
    }
    $spec = Get-Content $path -Raw | ConvertFrom-Json
    $issues = [System.Collections.Generic.List[string]]::new()
    $n = 0
    foreach ($case in @($spec.cases)) {
        $n++
        $fp = Join-Path $Root $case.path
        if (-not (Test-Path $fp)) { $issues.Add("$($case.id): missing $($case.path)"); continue }
        $text = Get-Content $fp -Raw
        foreach ($needle in @($case.mustContain)) {
            if ($text.IndexOf([string]$needle, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                $issues.Add("$($case.id): missing '$needle' in $($case.path)")
            }
        }
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = @($issues); Checked = $n }
}

function Test-L1PromoteSubset {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $issues = [System.Collections.Generic.List[string]]::new()
    $budget = Test-DescriptionBudget -Root $Root
    if (-not $budget.Pass) { $issues.Add("description budget $($budget.Total)/$($budget.Max)") }
    $hooks = Test-HooksManifest -Root $Root
    if (-not $hooks.Pass) { $issues.Add('hooks.json invalid') }
    $graph = Test-SkillsGraph -Root $Root
    if (-not $graph.Pass) { $issues.Add('skills.graph.json invalid') }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = @($issues) }
}

function Invoke-L2PromoteGate {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $l1 = Test-L1PromoteSubset -Root $Root
    if (-not $l1.Pass) {
        return [pscustomobject]@{ Pass = $false; Issues = @($l1.Issues | ForEach-Object { "L1: $_" }) }
    }
    $l2 = Invoke-L2FixtureSuite -Root $Root
    if (-not $l2.Pass) {
        return [pscustomobject]@{ Pass = $false; Issues = @($l2.Issues | ForEach-Object { "L2: $_" }) }
    }
    [pscustomobject]@{ Pass = $true; Issues = @() }
}

Export-ModuleMember -Function Get-ContractMarkers, Test-MarkersPreserved, Test-HandbookVerifyIntact,
    Test-GoldenPathShape, Invoke-L2FixtureSuite, Test-L3StaticMarkers, Test-L1PromoteSubset, Invoke-L2PromoteGate
