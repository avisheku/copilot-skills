param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$out = Export-CompareReport -Root $Root
Write-Host "Report JSON: $($out.Json)"
Write-Host "Report HTML: $($out.Html)"
$out.Board.leaderboard | Format-Table -AutoSize
$out.Board.lifts | Format-Table -AutoSize
