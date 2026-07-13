param(
    [string]$Goal = 'continue session',
    [string[]]$Completed = @(),
    [string[]]$Remaining = @(),
    [string]$Blockers = '',
    [string]$NextAsk = '',
    [string]$TaskKind = 'implement',
    [switch]$SkipAsk,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

Invoke-ContextCompact -Goal $Goal -CompletedSteps $Completed -RemainingSteps $Remaining `
    -Blockers $Blockers -NextAsk $NextAsk -TaskKind $TaskKind -SkipAsk:$SkipAsk -Root $Root
