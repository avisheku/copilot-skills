# Copilot Skills — Mixture of Agents (MoA-Lite)
# Inspired by togethercomputer/MoA (Apache-2.0) — do not vendor.

function Get-MoAConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\moa\profiles.json'
    if (-not (Test-Path $path)) { throw "MoA config missing: $path" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Get-MoAProfile {
    param(
        [string]$ProfileId = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-MoAConfig -Root $Root
    if (-not $ProfileId) { $ProfileId = $cfg.defaultProfile }
    $prof = $cfg.profiles.$ProfileId
    if (-not $prof) { throw "MoA profile not found: $ProfileId" }
    return [pscustomobject]@{
        Id      = $ProfileId
        Config  = $cfg
        Profile = $prof
    }
}

function Get-MoAAggregatorPrompt {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-Content (Join-Path $Root 'config\moa\aggregator-system.md') -Raw
}

function Get-MoAProposerPrompt {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-Content (Join-Path $Root 'config\moa\proposer-system.md') -Raw
}

function New-MoARunPlan {
    param(
        [Parameter(Mandatory)][string]$Query,
        [string]$ProfileId = '',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $bundle = Get-MoAProfile -ProfileId $ProfileId -Root $Root
    $cfg = $bundle.Config
    $prof = $bundle.Profile
    $runId = [guid]::NewGuid().ToString('n').Substring(0, 12)
    $proposers = @()
    foreach ($p in $prof.proposers) {
        $proposers += @{
            id       = [string]$p.id
            family   = [string]$p.family
            tipTask  = [string]$p.tipTask
            tipCard  = ('config/models/tips/{0}.md' -f $p.family)
            maxChars = [int]$cfg.maxProposalChars
        }
    }
    @{
        type          = 'MoARunPlan'
        runId         = $runId
        profile       = $bundle.Id
        label         = [string]$prof.label
        query         = $Query
        layers        = 2
        proposers     = $proposers
        aggregator    = @{
            id      = [string]$prof.aggregator.id
            family  = [string]$prof.aggregator.family
            tipTask = [string]$prof.aggregator.tipTask
            tipCard = ('config/models/tips/{0}.md' -f $prof.aggregator.family)
        }
        parallelGroup = ('moa-{0}' -f $runId)
        minSuccessful = [int]$cfg.minSuccessfulProposers
        createdAt     = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Limit-MoAProposalText {
    param([string]$Text, [int]$MaxChars = 1200)
    if (-not $Text) { return '' }
    $t = $Text.Trim()
    if ($t.Length -le $MaxChars) { return $t }
    $keep = [Math]::Max(0, $MaxChars - 14)
    return ($t.Substring(0, $keep) + '...[truncated]')
}

function New-MoAProposalPack {
    param(
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][object[]]$Proposals,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-MoAConfig -Root $Root
    $max = [int]$cfg.maxProposalChars
    $items = @()
    $i = 0
    foreach ($p in $Proposals) {
        $i++
        $text = if ($p.text) { $p.text } elseif ($p.content) { $p.content } else { [string]$p }
        $clipped = Limit-MoAProposalText -Text $text -MaxChars $max
        $items += [ordered]@{
            n      = $i
            id     = if ($p.id) { $p.id } else { ('p{0}' -f $i) }
            family = if ($p.family) { $p.family } else { '' }
            text   = $clipped
            chars  = $clipped.Length
        }
    }
    $pack = [ordered]@{
        type      = 'MoAProposalPack'
        runId     = $RunId
        count     = $items.Count
        proposals = $items
        packedAt  = (Get-Date).ToUniversalTime().ToString('o')
    }
    $dir = Join-Path $Root 'memory\moa'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $path = Join-Path $dir ('{0}-proposals.json' -f $RunId)
    $json = ConvertTo-Json -InputObject $pack -Depth 6 -Compress
    Set-Content -Path $path -Value $json -Encoding utf8
    return [pscustomobject]@{ Pack = $pack; Path = $path }
}

function Get-MoAAggregatorUserMessage {
    param(
        [Parameter(Mandatory)][string]$Query,
        [Parameter(Mandatory)]$ProposalPack,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($p in $ProposalPack.proposals) {
        [void]$lines.Add(('{0}. [{1}/{2}] {3}' -f $p.n, $p.id, $p.family, $p.text))
    }
    $sys = Get-MoAAggregatorPrompt -Root $Root
    $nl = [Environment]::NewLine
    $body = [string]::Join($nl + $nl, $lines)
    return ($sys + $nl + $nl + $body + $nl + $nl + 'User query:' + $nl + $Query)
}

function Save-MoARunState {
    param(
        [Parameter(Mandatory)]$Plan,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $dir = Join-Path $Root 'memory\moa'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $path = Join-Path $dir ('{0}-plan.json' -f $Plan.runId)
    $json = ConvertTo-Json -InputObject $Plan -Depth 6 -Compress
    Set-Content -Path $path -Value $json -Encoding utf8
    return $path
}

function Write-MoALedger {
    param(
        [string]$RunId,
        [string]$Profile,
        [int]$ProposerCount,
        [int]$TokensEst = 0,
        [ValidateSet('ok','warn','error')][string]$Outcome = 'ok',
        [string]$Phase = 'run',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $tool = '{0}/{1}/p{2}/{3}' -f $Phase, $Profile, $ProposerCount, $RunId
    Write-LedgerEntry -Skill 'moa' -Tool $tool -Outcome $Outcome -TokensEst $TokensEst -Root $Root
}

function Compare-MoAToBaseline {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [int]$Tail = 500
    )
    $entries = @(Get-LedgerEntries -Root $Root -Tail $Tail)
    $moa = @($entries | Where-Object { $_.skill -eq 'moa' -and $_.outcome -eq 'ok' })
    $single = @($entries | Where-Object { $_.skill -eq 'do' -and $_.outcome -eq 'ok' })
    function MedianTokens($arr) {
        $vals = @($arr | ForEach-Object { [int]$_.tokens_est } | Sort-Object)
        if ($vals.Count -eq 0) { return $null }
        $mid = [int][Math]::Floor(($vals.Count - 1) / 2)
        return $vals[$mid]
    }
    $moaMed = MedianTokens $moa
    $doMed = MedianTokens $single
    [pscustomobject]@{
        moaOkCount    = $moa.Count
        doOkCount     = $single.Count
        moaMedianTok  = $moaMed
        doMedianTok   = $doMed
        recommendWire = ($moa.Count -ge 5 -and $null -ne $moaMed -and $null -ne $doMed -and $moaMed -le $doMed)
    }
}

Export-ModuleMember -Function Get-MoAConfig, Get-MoAProfile, Get-MoAAggregatorPrompt, Get-MoAProposerPrompt,
    New-MoARunPlan, Limit-MoAProposalText, New-MoAProposalPack, Get-MoAAggregatorUserMessage,
    Save-MoARunState, Write-MoALedger, Compare-MoAToBaseline
