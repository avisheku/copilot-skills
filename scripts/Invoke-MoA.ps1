param(
    [Parameter(Mandatory)][string]$Query,
    [ValidateSet('lite','full','research')][string]$Profile = 'lite',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$plan = New-MoARunPlan -Query $Query -ProfileId $Profile -Root $Root
$path = Save-MoARunState -Plan $plan -Root $Root
Write-MoALedger -RunId $plan.runId -Profile $Profile -ProposerCount $plan.proposers.Count -Phase 'prep' -Root $Root | Out-Null

[pscustomobject]@{
    runId         = $plan.runId
    profile       = $Profile
    proposers     = $plan.proposers.Count
    parallelGroup = $plan.parallelGroup
    planPath      = $path
    next          = 'Fork proposers (agents/moa-proposer.agent.md), then Invoke-MoAFinish.ps1'
}
