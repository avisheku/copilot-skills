param(
    [string]$Family = 'universal',
    [string]$Goal = 'session',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

Save-ModelState -ActiveFamily $Family -Root $Root | Out-Null
Save-McpSnapshot -Root $Root | Out-Null
Restore-McpMinimal -Root $Root | Out-Null
Invoke-ContextPack -PackId 'default' -Root $Root | Out-Null
$tips = Invoke-ModelTipInject -Family $Family -Task 'orchestrate' -Root $Root
Write-LedgerEntry -Skill 'do' -Tool 'Invoke-DoPrep' -Outcome 'ok' -TokensEst 0 -Root $Root | Out-Null

[pscustomobject]@{
    goal    = $Goal
    family  = $tips.family
    mcp     = 'minimal'
    pack    = 'default'
    ledger  = (Get-LedgerPath -Root $Root)
}
