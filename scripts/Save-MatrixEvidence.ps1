param(
    [Parameter(Mandatory)][string]$TaskKind,
    [Parameter(Mandatory)][string]$Family,
    [ValidateSet('low', 'medium', 'high', 'extra')][string]$Effort = 'medium',
    [ValidateSet('ok', 'warn', 'deny', 'error')][string]$Outcome = 'ok',
    [int]$TokensEst = 0,
    [double]$QualityScore = -1,
    [string]$EscalatedFrom = '',
    [string]$EscalateReason = '',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$q = $null
if ($QualityScore -ge 0) { $q = $QualityScore }
Save-MatrixEvidenceRun -TaskKind $TaskKind -Family $Family -Effort $Effort `
    -Outcome $Outcome -TokensEst $TokensEst -QualityScore $q `
    -EscalatedFrom $EscalatedFrom -EscalateReason $EscalateReason -Root $Root
