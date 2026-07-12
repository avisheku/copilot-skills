param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Html
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$board = Invoke-CompareScoreboard -Root $Root
$board | ConvertTo-Json -Depth 8
if ($Html) {
    Export-CompareReport -Root $Root | Out-Null
    Write-Host "HTML: $(Join-Path $Root 'evidence\compare\report.html')"
}
