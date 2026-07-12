param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$out = Export-UpgradeReport -Root $Root
Write-Host "Upgrade report JSON: $($out.Json)"
Write-Host "Upgrade report MD:   $($out.Markdown)"
Write-Host "Summary: action=$($out.Scan.summary.action) review=$($out.Scan.summary.review) ok=$($out.Scan.summary.ok)"
$out.Scan.components | Select-Object id, status, kind | Format-Table -AutoSize
