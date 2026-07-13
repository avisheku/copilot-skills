param(
    [string]$Family = '',
    [string]$Effort = '',
    [string]$TaskKind = 'implement',
    [string]$Goal = 'session',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

Save-McpSnapshot -Root $Root | Out-Null
Restore-McpMinimal -Root $Root | Out-Null
Invoke-ContextPack -PackId 'default' -Root $Root | Out-Null

$rec = Invoke-MatrixDoPrep -TaskKind $TaskKind -Family $Family -Effort $Effort -Root $Root
Write-LedgerEntry -Skill 'do' -Tool 'Invoke-DoPrep' -Outcome 'ok' -TokensEst 0 -Root $Root | Out-Null

[pscustomobject]@{
    goal     = $Goal
    taskKind = $TaskKind
    family   = $rec.family
    effort   = $rec.effort
    source   = $rec.source
    mcp      = 'minimal'
    pack     = 'default'
    ledger   = (Get-LedgerPath -Root $Root)
}
