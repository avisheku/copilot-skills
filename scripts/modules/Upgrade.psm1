# Copilot Skills — Phase 10 upgrade / frontier scan (local inventory; research is agent-driven)

function Get-UpgradeRegistry {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\upgrade\registry.json'
    if (-not (Test-Path $path)) { throw "Upgrade registry missing: $path" }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-ResearchSources {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\research\sources.json'
    if (-not (Test-Path $path)) { return @() }
    $j = Get-Content $path -Raw | ConvertFrom-Json
    @($j.entries)
}

function Test-UpgradeComponent {
    param(
        [Parameter(Mandatory)]$Component,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $findings = [System.Collections.Generic.List[object]]::new()
    $status = 'ok'
    $path = Join-Path $Root (($Component.path -replace '/', '\'))

    foreach ($chk in @($Component.check)) {
        switch ($chk) {
            'file-exists' {
                if (-not (Test-Path $path)) {
                    $findings.Add([ordered]@{ severity = 'high'; code = 'missing-file'; detail = $Component.path }) | Out-Null
                    $status = 'action'
                }
            }
            'version-table' {
                if (-not (Test-Path $path)) {
                    $findings.Add([ordered]@{ severity = 'high'; code = 'missing-versions'; detail = 'VERSIONS.md' }) | Out-Null
                    $status = 'action'
                } else {
                    $t = Get-Content $path -Raw
                    if ($t -notmatch 'Pack') {
                        $findings.Add([ordered]@{ severity = 'med'; code = 'versions-incomplete'; detail = 'no Pack row' }) | Out-Null
                        $status = 'review'
                    }
                    $findings.Add([ordered]@{ severity = 'info'; code = 'review-pack-version'; detail = 'Confirm Pack version vs shipped phases' }) | Out-Null
                    if ($status -eq 'ok') { $status = 'review' }
                }
            }
            'graph-valid' {
                $g = Test-SkillsGraph -Root $Root
                if (-not $g.Pass) {
                    $findings.Add([ordered]@{ severity = 'high'; code = 'graph-invalid'; detail = ($g.Issues -join '; ') }) | Out-Null
                    $status = 'action'
                }
            }
            'abidance-mvp' {
                $bad = @(Test-AllSkillsAbidance -Root $Root | Where-Object { $_.Phase -eq 'mvp' -and -not $_.Pass })
                if ($bad.Count -gt 0) {
                    $findings.Add([ordered]@{ severity = 'high'; code = 'abidance-fail'; detail = ($bad.Skill -join ',') }) | Out-Null
                    $status = 'action'
                }
            }
            'tip-cards-exist' {
                if (-not (Test-Path $path)) {
                    $findings.Add([ordered]@{ severity = 'high'; code = 'matrix-missing'; detail = 'matrix.json' }) | Out-Null
                    $status = 'action'
                } else {
                    $m = Get-Content $path -Raw | ConvertFrom-Json
                    foreach ($fam in @($m.families.PSObject.Properties.Name)) {
                        $tip = $m.families.$fam.tipCard
                        if ($tip) {
                            $tp = Join-Path $Root "config\models\$($tip -replace '/', '\')"
                            if (-not (Test-Path $tp)) {
                                $findings.Add([ordered]@{ severity = 'high'; code = 'tip-missing'; detail = $tip }) | Out-Null
                                $status = 'action'
                            } else {
                                $ageDays = [int]((Get-Date) - (Get-Item $tp).LastWriteTime).TotalDays
                                if ($ageDays -gt 90) {
                                    $findings.Add([ordered]@{ severity = 'med'; code = 'tip-stale'; detail = "$tip ageDays=$ageDays - re-check provider docs" }) | Out-Null
                                    if ($status -eq 'ok') { $status = 'review' }
                                }
                            }
                        }
                    }
                    $findings.Add([ordered]@{ severity = 'info'; code = 'research-model-tips'; detail = 'Research provider changelogs; update tip cards if APIs/prompting guidance changed' }) | Out-Null
                    if ($status -eq 'ok') { $status = 'review' }
                }
            }
            'baseline-exists' {
                $bp = Join-Path $Root 'evidence\quality-baseline.json'
                if (-not (Test-Path $bp)) {
                    $findings.Add([ordered]@{ severity = 'med'; code = 'ics-baseline-missing'; detail = 'run Update-QualityBaseline.ps1' }) | Out-Null
                    if ($status -eq 'ok') { $status = 'review' }
                }
            }
            'sources-populated' {
                $entries = @(Get-ResearchSources -Root $Root)
                if ($entries.Count -lt 5) {
                    $findings.Add([ordered]@{ severity = 'med'; code = 'sources-thin'; detail = "entries=$($entries.Count)" }) | Out-Null
                    if ($status -eq 'ok') { $status = 'review' }
                }
                $findings.Add([ordered]@{ severity = 'info'; code = 'frontier-pass'; detail = 'Agent: scan SOURCES + news URLs for new/deprecated items' }) | Out-Null
                if ($status -eq 'ok') { $status = 'review' }
            }
            'verify-blocks' {
                if (-not (Test-Path $path)) {
                    $findings.Add([ordered]@{ severity = 'high'; code = 'handbook-missing'; detail = 'HANDBOOK.md' }) | Out-Null
                    $status = 'action'
                } else {
                    $t = Get-Content $path -Raw
                    if ($t -notmatch '(?m)^VERIFY:') {
                        $findings.Add([ordered]@{ severity = 'high'; code = 'verify-missing'; detail = 'VERIFY blocks' }) | Out-Null
                        $status = 'action'
                    }
                }
            }
            default {
                $findings.Add([ordered]@{ severity = 'info'; code = 'unknown-check'; detail = $chk }) | Out-Null
            }
        }
    }

    if (@($Component.watch).Count -gt 0) {
        $findings.Add([ordered]@{
            severity = 'info'
            code     = 'watchlist'
            detail   = (@($Component.watch) -join ' | ')
        }) | Out-Null
    }

    [pscustomobject]@{
        id       = $Component.id
        kind     = $Component.kind
        path     = $Component.path
        status   = $status
        findings = @($findings)
        watch    = @($Component.watch)
    }
}

function Invoke-UpgradeScan {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $reg = Get-UpgradeRegistry -Root $Root
    $results = @()
    foreach ($c in @($reg.components)) {
        $results += Test-UpgradeComponent -Component $c -Root $Root
    }
    $action = @($results | Where-Object { $_.status -eq 'action' })
    $review = @($results | Where-Object { $_.status -eq 'review' })
    $sources = @(Get-ResearchSources -Root $Root)

    [pscustomobject]@{
        generatedAt    = (Get-Date).ToUniversalTime().ToString('o')
        packRoot       = $Root
        summary        = [ordered]@{
            components = $results.Count
            action     = $action.Count
            review     = $review.Count
            ok         = @($results | Where-Object { $_.status -eq 'ok' }).Count
        }
        components     = $results
        frontierTopics = @($reg.frontierTopics)
        researchSources = $sources
        nextSteps      = @(
            'For each status=action: fix locally or stage via /learn',
            'For each status=review: agent researches watch URLs + frontierTopics',
            'Promote instruction/model tip changes with upgrade-only /learn + CI',
            'Refresh ICS baseline only after intentional green upgrades',
            'Record compare runs after material harness changes (Phase 9)'
        )
    }
}

function Export-UpgradeReport {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        $Scan = $null
    )
    if ($null -eq $Scan) { $Scan = Invoke-UpgradeScan -Root $Root }
    $dir = Join-Path $Root 'evidence\upgrade'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $jsonPath = Join-Path $dir 'report.json'
    $mdPath = Join-Path $dir 'report.md'
    $Scan | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding utf8

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# Upgrade / frontier scan')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Generated: $($Scan.generatedAt)")
    [void]$sb.AppendLine("Summary: action=$($Scan.summary.action) review=$($Scan.summary.review) ok=$($Scan.summary.ok) / $($Scan.summary.components)")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Components')
    foreach ($c in @($Scan.components)) {
        [void]$sb.AppendLine("### $($c.id) ($($c.status))")
        [void]$sb.AppendLine("- kind: $($c.kind) · path: ``$($c.path)``")
        foreach ($f in @($c.findings)) {
            [void]$sb.AppendLine("  - [$($f.severity)] $($f.code): $($f.detail)")
        }
        [void]$sb.AppendLine('')
    }
    [void]$sb.AppendLine('## Frontier topics (research checklist)')
    foreach ($t in @($Scan.frontierTopics)) { [void]$sb.AppendLine("- [ ] $t") }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Research sources')
    foreach ($s in @($Scan.researchSources)) {
        [void]$sb.AppendLine("- [$($s.topic)]($($s.url))")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Next steps')
    $i = 1
    foreach ($n in @($Scan.nextSteps)) { [void]$sb.AppendLine("$i. $n"); $i++ }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Agent contract')
    [void]$sb.AppendLine('After research: propose concrete upgrades as `/learn` staging (upgrade-only). Do not auto-scrape or silent-overwrite. Run `Test-CI.ps1` before promote.')

    [System.IO.File]::WriteAllText($mdPath, $sb.ToString())
    Write-LedgerEntry -Skill 'upgrade' -Tool 'scan' -Outcome 'ok' -Root $Root | Out-Null
    return [pscustomobject]@{ Json = $jsonPath; Markdown = $mdPath; Scan = $Scan }
}

Export-ModuleMember -Function Get-UpgradeRegistry, Get-ResearchSources, Test-UpgradeComponent,
    Invoke-UpgradeScan, Export-UpgradeReport
