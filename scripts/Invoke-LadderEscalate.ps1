param(
    [Parameter(Mandatory)][string]$Query,
    [string]$TaskKind = 'implement',
    [string]$CurrentFamily = 'copilot-auto',
    [string]$CurrentEffort = 'medium',
    [int]$StepIndex = 0,
    [ValidateSet('ok', 'warn', 'deny', 'error')][string]$Outcome = 'error',
    [double]$QualityScore = -1,
    [switch]$Force,
    [string]$AttemptSummary = '',
    [string]$WhatWorked = '',
    [string]$Blockers = '',
    [string]$Artifacts = '',
    [string]$NextAsk = '',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$q = $null
if ($QualityScore -ge 0) { $q = $QualityScore }

$result = Invoke-LadderEscalate -TaskKind $TaskKind -Query $Query `
    -CurrentFamily $CurrentFamily -CurrentEffort $CurrentEffort -StepIndex $StepIndex `
    -Outcome $Outcome -QualityScore $q -Force:$Force `
    -AttemptSummary $AttemptSummary -WhatWorked $WhatWorked -Blockers $Blockers `
    -Artifacts $Artifacts -NextAsk $NextAsk -Root $Root

$result | ConvertTo-Json -Depth 6
