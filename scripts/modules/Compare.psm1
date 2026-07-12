# Copilot Skills — Phase 9 harness comparison (Arena-style Elo + lift + cost)

function Get-CompareRoot {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'evidence\compare'
}

function Get-CompareArms {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\compare\arms.json'
    (Get-Content $path -Raw | ConvertFrom-Json).arms
}

function Get-ComparePrices {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\compare\prices.json'
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-CompareTasks {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $dir = Join-Path $Root 'shared\fixtures\compare\tasks'
    if (-not (Test-Path $dir)) { return @() }
    Get-ChildItem $dir -Filter '*.json' | ForEach-Object {
        Get-Content $_.FullName -Raw | ConvertFrom-Json
    }
}

function Get-CompareRuns {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $dir = Join-Path (Get-CompareRoot -Root $Root) 'runs'
    if (-not (Test-Path $dir)) { return @() }
    Get-ChildItem $dir -Filter '*.json' | ForEach-Object {
        Get-Content $_.FullName -Raw | ConvertFrom-Json
    }
}

function Get-CompareEstimatedCostUsd {
    param(
        [string]$ModelId,
        [int]$TokensIn = 0,
        [int]$TokensOut = 0,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $prices = Get-ComparePrices -Root $Root
    $m = $prices.models | Where-Object { $_.id -eq $ModelId } | Select-Object -First 1
    if (-not $m) {
        $m = $prices.models | Where-Object { $_.id -eq 'default' } | Select-Object -First 1
    }
    if (-not $m) { return $null }
    $cost = ($TokensIn / 1000000.0) * [double]$m.inputPerMTok + ($TokensOut / 1000000.0) * [double]$m.outputPerMTok
    return [math]::Round($cost, 6)
}

function Save-CompareRun {
    param(
        [Parameter(Mandatory)][string]$TaskId,
        [Parameter(Mandatory)][string]$ArmId,
        [Parameter(Mandatory)][string]$ModelId,
        [string]$OutputText = '',
        [int]$TokensIn = 0,
        [int]$TokensOut = 0,
        [int]$TokensEst = 0,
        [int]$LatencyMs = 0,
        [double]$QualityPassRate = -1,
        [string]$Notes = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $tasks = @(Get-CompareTasks -Root $Root)
    if (-not ($tasks | Where-Object { $_.id -eq $TaskId })) {
        throw "Unknown taskId: $TaskId"
    }
    $arms = @(Get-CompareArms -Root $Root)
    if (-not ($arms | Where-Object { $_.id -eq $ArmId })) {
        throw "Unknown armId: $ArmId"
    }
    if ($TokensEst -le 0) { $TokensEst = $TokensIn + $TokensOut }
    $runId = [guid]::NewGuid().ToString('n').Substring(0, 12)
    $cost = Get-CompareEstimatedCostUsd -ModelId $ModelId -TokensIn $TokensIn -TokensOut $TokensOut -Root $Root
    $q = $null
    if ($QualityPassRate -ge 0) {
        $q = [ordered]@{ passRate = [math]::Round($QualityPassRate, 4); source = 'manual' }
    }
    $outDir = Join-Path (Get-CompareRoot -Root $Root) 'outputs'
    $runsDir = Join-Path (Get-CompareRoot -Root $Root) 'runs'
    New-Item -ItemType Directory -Force -Path $outDir, $runsDir | Out-Null
    $outPath = Join-Path $outDir "$runId.txt"
    if ($OutputText) { Set-Content -Path $outPath -Value $OutputText -Encoding utf8 }
    $rec = [ordered]@{
        runId      = $runId
        taskId     = $TaskId
        armId      = $ArmId
        modelId    = $ModelId
        tokens_in  = $TokensIn
        tokens_out = $TokensOut
        tokens_est = $TokensEst
        latency_ms = $LatencyMs
        cost_usd   = $cost
        quality    = $q
        outputPath = if ($OutputText) { "evidence/compare/outputs/$runId.txt" } else { $null }
        notes      = $Notes
        createdAt  = (Get-Date).ToUniversalTime().ToString('o')
    }
    $path = Join-Path $runsDir "$runId.json"
    $rec | ConvertTo-Json -Depth 6 | Set-Content $path -Encoding utf8
    Write-LedgerEntry -Skill 'compare' -Tool $ArmId -Outcome 'ok' -TokensEst $TokensEst -Root $Root | Out-Null
    return $rec
}

function Get-CompareQuality {
    param($Run)
    if ($null -eq $Run.quality) { return $null }
    if ($null -ne $Run.quality.passRate) { return [double]$Run.quality.passRate }
    if ($null -ne $Run.quality.pass) { return $(if ($Run.quality.pass) { 1.0 } else { 0.0 }) }
    return $null
}

function Update-EloRatings {
    param(
        [hashtable]$Ratings,
        [string]$Winner,
        [string]$Loser,
        [double]$K = 24,
        [switch]$Tie
    )
    if (-not $Ratings.ContainsKey($Winner)) { $Ratings[$Winner] = 1000.0 }
    if (-not $Ratings.ContainsKey($Loser)) { $Ratings[$Loser] = 1000.0 }
    $ra = [double]$Ratings[$Winner]
    $rb = [double]$Ratings[$Loser]
    $ea = 1.0 / (1.0 + [math]::Pow(10, ($rb - $ra) / 400.0))
    $eb = 1.0 / (1.0 + [math]::Pow(10, ($ra - $rb) / 400.0))
    if ($Tie) {
        $Ratings[$Winner] = [math]::Round($ra + $K * (0.5 - $ea), 2)
        $Ratings[$Loser] = [math]::Round($rb + $K * (0.5 - $eb), 2)
    } else {
        $Ratings[$Winner] = [math]::Round($ra + $K * (1 - $ea), 2)
        $Ratings[$Loser] = [math]::Round($rb + $K * (0 - $eb), 2)
    }
}

function Get-CompareArmKey {
    param($Run)
    return "$($Run.armId)|$($Run.modelId)"
}

function Invoke-CompareScoreboard {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $runs = @(Get-CompareRuns -Root $Root)
    $byTask = $runs | Group-Object taskId
    $elo = @{}
    $pairCount = 0

    foreach ($g in $byTask) {
        $list = @($g.Group)
        for ($i = 0; $i -lt $list.Count; $i++) {
            for ($j = $i + 1; $j -lt $list.Count; $j++) {
                $a = $list[$i]; $b = $list[$j]
                $ka = Get-CompareArmKey $a
                $kb = Get-CompareArmKey $b
                if ($ka -eq $kb) { continue }
                $qa = Get-CompareQuality $a
                $qb = Get-CompareQuality $b
                if ($null -eq $qa -or $null -eq $qb) { continue }
                $pairCount++
                if ([math]::Abs($qa - $qb) -lt 0.05) {
                    # tie on quality → cheaper wins, else tie
                    $ca = if ($null -ne $a.cost_usd) { [double]$a.cost_usd } else { [double]::MaxValue }
                    $cb = if ($null -ne $b.cost_usd) { [double]$b.cost_usd } else { [double]::MaxValue }
                    if ([math]::Abs($ca - $cb) -lt 1e-9) {
                        Update-EloRatings -Ratings $elo -Winner $ka -Loser $kb -Tie
                    } elseif ($ca -lt $cb) {
                        Update-EloRatings -Ratings $elo -Winner $ka -Loser $kb
                    } else {
                        Update-EloRatings -Ratings $elo -Winner $kb -Loser $ka
                    }
                } elseif ($qa -gt $qb) {
                    Update-EloRatings -Ratings $elo -Winner $ka -Loser $kb
                } else {
                    Update-EloRatings -Ratings $elo -Winner $kb -Loser $ka
                }
            }
        }
    }

    # Aggregates per armKey
    $agg = @{}
    foreach ($r in $runs) {
        $k = Get-CompareArmKey $r
        if (-not $agg.ContainsKey($k)) {
            $agg[$k] = [ordered]@{
                armKey = $k; armId = $r.armId; modelId = $r.modelId
                n = 0; qualitySum = 0.0; qualityN = 0
                tokensSum = 0; costSum = 0.0; costN = 0; latencySum = 0
            }
        }
        $agg[$k].n++
        $q = Get-CompareQuality $r
        if ($null -ne $q) { $agg[$k].qualitySum += $q; $agg[$k].qualityN++ }
        $agg[$k].tokensSum += [int]$r.tokens_est
        if ($null -ne $r.cost_usd) { $agg[$k].costSum += [double]$r.cost_usd; $agg[$k].costN++ }
        $agg[$k].latencySum += [int]$r.latency_ms
    }

    $rows = @()
    foreach ($k in $agg.Keys) {
        $a = $agg[$k]
        $qAvg = if ($a.qualityN -gt 0) { [math]::Round($a.qualitySum / $a.qualityN, 4) } else { $null }
        $costAvg = if ($a.costN -gt 0) { [math]::Round($a.costSum / $a.costN, 6) } else { $null }
        $tokAvg = if ($a.n -gt 0) { [math]::Round($a.tokensSum / [double]$a.n, 1) } else { $null }
        $latAvg = if ($a.n -gt 0) { [math]::Round($a.latencySum / [double]$a.n, 0) } else { $null }
        $qpd = $null
        if ($null -ne $qAvg -and $null -ne $costAvg -and $costAvg -gt 0) {
            $qpd = [math]::Round($qAvg / $costAvg, 2)
        }
        $eloScore = if ($elo.ContainsKey($k)) { $elo[$k] } else { 1000.0 }
        $rows += [pscustomobject]@{
            armKey             = $k
            armId              = $a.armId
            modelId            = $a.modelId
            elo                = $eloScore
            n                  = $a.n
            qualityAvg         = $qAvg
            tokensAvg          = $tokAvg
            costAvgUsd         = $costAvg
            latencyAvgMs       = $latAvg
            qualityPerDollar   = $qpd
        }
    }

    # Harness lift vs solo for same model
    $lifts = @()
    $byModel = $rows | Group-Object modelId
    foreach ($mg in $byModel) {
        $solo = @($mg.Group | Where-Object { $_.armId -eq 'solo' } | Select-Object -First 1)
        if (-not $solo) { continue }
        foreach ($r in @($mg.Group | Where-Object { $_.armId -ne 'solo' })) {
            if ($null -eq $solo.qualityAvg -or $null -eq $r.qualityAvg) { continue }
            $lifts += [pscustomobject]@{
                modelId     = $mg.Name
                armId       = $r.armId
                qualityLift = [math]::Round([double]$r.qualityAvg - [double]$solo.qualityAvg, 4)
                tokenDelta  = if ($null -ne $solo.tokensAvg -and $null -ne $r.tokensAvg) {
                    [math]::Round([double]$r.tokensAvg - [double]$solo.tokensAvg, 1)
                } else { $null }
                costDelta   = if ($null -ne $solo.costAvgUsd -and $null -ne $r.costAvgUsd) {
                    [math]::Round([double]$r.costAvgUsd - [double]$solo.costAvgUsd, 6)
                } else { $null }
            }
        }
    }

    # Skill effectiveness: average quality among runs whose task hints include skill
    $tasks = @(Get-CompareTasks -Root $Root)
    $taskMap = @{}
    foreach ($t in $tasks) { $taskMap[$t.id] = $t }
    $skillStats = @{}
    foreach ($r in $runs) {
        $t = $taskMap[$r.taskId]
        if (-not $t) { continue }
        $q = Get-CompareQuality $r
        if ($null -eq $q) { continue }
        foreach ($sk in @($t.skillHints)) {
            if (-not $skillStats.ContainsKey($sk)) {
                $skillStats[$sk] = @{ n = 0; qSum = 0.0; harnessN = 0; harnessQ = 0.0; soloN = 0; soloQ = 0.0 }
            }
            $skillStats[$sk].n++
            $skillStats[$sk].qSum += $q
            if ($r.armId -eq 'solo') { $skillStats[$sk].soloN++; $skillStats[$sk].soloQ += $q }
            else { $skillStats[$sk].harnessN++; $skillStats[$sk].harnessQ += $q }
        }
    }
    $skillRows = @()
    foreach ($sk in $skillStats.Keys) {
        $s = $skillStats[$sk]
        $hq = if ($s.harnessN -gt 0) { $s.harnessQ / $s.harnessN } else { $null }
        $sq = if ($s.soloN -gt 0) { $s.soloQ / $s.soloN } else { $null }
        $skillRows += [pscustomobject]@{
            skill       = $sk
            n           = $s.n
            harnessAvg  = if ($null -ne $hq) { [math]::Round($hq, 4) } else { $null }
            soloAvg     = if ($null -ne $sq) { [math]::Round($sq, 4) } else { $null }
            lift        = if ($null -ne $hq -and $null -ne $sq) { [math]::Round($hq - $sq, 4) } else { $null }
        }
    }

    [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        runCount    = $runs.Count
        pairCount   = $pairCount
        leaderboard = @($rows | Sort-Object elo -Descending)
        lifts       = $lifts
        skills      = @($skillRows | Sort-Object lift -Descending)
    }
}

function Export-CompareReport {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [string]$OutHtml,
        [string]$OutJson
    )
    $board = Invoke-CompareScoreboard -Root $Root
    $dir = Get-CompareRoot -Root $Root
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    if (-not $OutJson) { $OutJson = Join-Path $dir 'report.json' }
    if (-not $OutHtml) { $OutHtml = Join-Path $dir 'report.html' }
    $board | ConvertTo-Json -Depth 8 | Set-Content $OutJson -Encoding utf8

    $lbRows = ''
    $rank = 0
    foreach ($r in @($board.leaderboard)) {
        $rank++
        $lbRows += "<tr><td>$rank</td><td>$([System.Net.WebUtility]::HtmlEncode($r.armId))</td><td>$([System.Net.WebUtility]::HtmlEncode($r.modelId))</td><td>$($r.elo)</td><td>$($r.qualityAvg)</td><td>$($r.tokensAvg)</td><td>$($r.costAvgUsd)</td><td>$($r.qualityPerDollar)</td><td>$($r.n)</td></tr>"
    }
    $liftRows = ''
    foreach ($l in @($board.lifts)) {
        $liftRows += "<tr><td>$([System.Net.WebUtility]::HtmlEncode($l.modelId))</td><td>$([System.Net.WebUtility]::HtmlEncode($l.armId))</td><td>$($l.qualityLift)</td><td>$($l.tokenDelta)</td><td>$($l.costDelta)</td></tr>"
    }
    $skRows = ''
    foreach ($s in @($board.skills)) {
        $skRows += "<tr><td>$([System.Net.WebUtility]::HtmlEncode($s.skill))</td><td>$($s.lift)</td><td>$($s.harnessAvg)</td><td>$($s.soloAvg)</td><td>$($s.n)</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/><title>Harness Compare Report</title>
<style>
body{font-family:Segoe UI,system-ui,sans-serif;margin:2rem;background:#0f1419;color:#e7ecf1}
h1{font-size:1.35rem} h2{font-size:1.05rem;color:#c5d4e4}
.meta{color:#9aa7b5;margin-bottom:1rem}
table{border-collapse:collapse;width:100%;font-size:.9rem;margin:.5rem 0 1.5rem}
th,td{text-align:left;padding:.4rem .5rem;border-bottom:1px solid #2a3648}
th{color:#9aa7b5} section{background:#1a2332;padding:1rem 1.25rem;border-radius:8px;margin:1rem 0}
</style></head><body>
<h1>Harness comparison leaderboard</h1>
<p class="meta">Generated $($board.generatedAt) · runs=$($board.runCount) · pairs=$($board.pairCount) · Elo K=24 (Arena-style)</p>
<section><h2>Ranks (arm x model)</h2>
<table><thead><tr><th>#</th><th>Arm</th><th>Model</th><th>Elo</th><th>Quality</th><th>Tokens</th><th>`$</th><th>Q/`$</th><th>n</th></tr></thead>
<tbody>$lbRows</tbody></table></section>
<section><h2>Harness lift vs solo (same model)</h2>
<table><thead><tr><th>Model</th><th>Arm</th><th>Quality lift</th><th>Token delta</th><th>Cost delta</th></tr></thead>
<tbody>$liftRows</tbody></table></section>
<section><h2>Skill effectiveness (hinted tasks)</h2>
<table><thead><tr><th>Skill</th><th>Lift</th><th>Harness avg</th><th>Solo avg</th><th>n</th></tr></thead>
<tbody>$skRows</tbody></table></section>
<p class="meta">Proof artifact for pack effectiveness. Not a public Arena scrape — your tasks, your arms.</p>
</body></html>
"@
    [System.IO.File]::WriteAllText($OutHtml, $html)
    return [pscustomobject]@{ Html = $OutHtml; Json = $OutJson; Board = $board }
}

Export-ModuleMember -Function Get-CompareArms, Get-CompareTasks, Get-CompareRuns, Get-ComparePrices,
    Get-CompareEstimatedCostUsd, Save-CompareRun, Invoke-CompareScoreboard, Export-CompareReport, Get-CompareRoot
