param(
    [int]$Tail = 1000,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$stats = Get-LedgerStats -Root $Root -Tail $Tail
$stats | Format-List
$stats | ConvertTo-Json -Depth 5
