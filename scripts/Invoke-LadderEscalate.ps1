param(
    [Parameter(Mandatory)][string]$Query,
    [string]$TaskKind = 'implement',
    [string]$CurrentFamily = 'universal',
    [string]$CurrentEffort = 'medium',
    [int]$StepIndex = 0,
    [string]$AttemptSummary = '',
    [string]$WhatWorked = '',
    [string]$Blockers = '',
    [string]$Artifacts = '',
    [string]$NextAsk = '',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

# Log failed attempt at current cell
Save-MatrixEvidenceRun -TaskKind $TaskKind -Family $CurrentFamily -Effort $CurrentEffort `
    -Outcome 'error' -EscalatedFrom '' -Root $Root | Out-Null

$result = Invoke-LadderEscalate -TaskKind $TaskKind -Query $Query `
    -CurrentFamily $CurrentFamily -CurrentEffort $CurrentEffort -StepIndex $StepIndex `
    -AttemptSummary $AttemptSummary -WhatWorked $WhatWorked -Blockers $Blockers `
    -Artifacts $Artifacts -NextAsk $NextAsk -Root $Root

$result | ConvertTo-Json -Depth 6
