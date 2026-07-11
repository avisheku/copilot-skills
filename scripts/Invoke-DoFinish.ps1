param(
    [string]$Goal = 'session complete',
    [string[]]$Completed = @(),
    [string[]]$Remaining = @(),
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

Restore-ContextDefault -Root $Root | Out-Null
Restore-ModelState -Root $Root | Out-Null
Restore-McpSnapshot -Root $Root | Out-Null
$thresh = Test-SessionTokenThreshold -Root $Root
$pack = New-HandoffPack -Goal $Goal -CompletedSteps $Completed -RemainingSteps $Remaining -Root $Root
Write-LedgerEntry -Skill 'do' -Tool 'Invoke-DoFinish' -Outcome 'ok' -Root $Root | Out-Null

[pscustomobject]@{
    handoff = $pack.type
    tokens  = $thresh
    restored = $true
}
