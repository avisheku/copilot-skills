param(
    [int]$Iterations = 0,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$result = Invoke-LoopRun -MaxIterations $Iterations -Root $Root
$result | ConvertTo-Json -Depth 5
