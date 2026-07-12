param(
    [Parameter(Mandatory)][string]$RunId,
    [Parameter(Mandatory)][string]$ProposalsJson,
    [int]$TokensEst = 0,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$proposals = $ProposalsJson | ConvertFrom-Json
if ($proposals -isnot [System.Array]) { $proposals = @($proposals) }

$cfg = Get-MoAConfig -Root $Root
if ($proposals.Count -lt [int]$cfg.minSuccessfulProposers) {
    throw "Need at least $($cfg.minSuccessfulProposers) proposals; got $($proposals.Count)"
}

$packed = New-MoAProposalPack -RunId $RunId -Proposals $proposals -Root $Root
$planPath = Join-Path $Root "memory\moa\$RunId-plan.json"
$query = ''
$profile = 'lite'
if (Test-Path $planPath) {
    $plan = Get-Content $planPath -Raw | ConvertFrom-Json
    $query = $plan.query
    $profile = $plan.profile
}

$aggMsg = Get-MoAAggregatorUserMessage -Query $query -ProposalPack $packed.Pack
$aggPath = Join-Path $Root "memory\moa\$RunId-aggregator-prompt.txt"
$aggMsg | Set-Content $aggPath -Encoding utf8

Write-MoALedger -RunId $RunId -Profile $profile -ProposerCount $proposals.Count -TokensEst $TokensEst -Phase 'pack' -Root $Root | Out-Null

[pscustomobject]@{
    runId              = $RunId
    proposalPath       = $packed.Path
    aggregatorPrompt   = $aggPath
    proposalCount      = $packed.Pack.count
    next               = 'Run aggregator (agents/moa-aggregator.agent.md) with aggregator prompt file'
}
