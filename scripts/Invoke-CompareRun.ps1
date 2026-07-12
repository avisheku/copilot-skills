param(
    [Parameter(Mandatory)][string]$TaskId,
    [Parameter(Mandatory)][string]$ArmId,
    [Parameter(Mandatory)][string]$ModelId,
    [string]$OutputFile,
    [string]$OutputText,
    [int]$TokensIn = 0,
    [int]$TokensOut = 0,
    [int]$TokensEst = 0,
    [int]$LatencyMs = 0,
    [double]$QualityPassRate = -1,
    [string]$Notes = '',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

if ($OutputFile -and -not $OutputText) {
    $OutputText = Get-Content $OutputFile -Raw
}

$rec = Save-CompareRun -TaskId $TaskId -ArmId $ArmId -ModelId $ModelId `
    -OutputText $OutputText -TokensIn $TokensIn -TokensOut $TokensOut `
    -TokensEst $TokensEst -LatencyMs $LatencyMs -QualityPassRate $QualityPassRate `
    -Notes $Notes -Root $Root

$rec | ConvertTo-Json -Depth 6
Write-Host "Saved run $($rec.runId)"
