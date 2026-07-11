param([switch]$Check, [string]$Skill)

$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Write-Host "Sync-CopilotSkills: Check=$Check Root=$Root"
if ($Check) { Write-Host "Drift check: Phase 1 pending" }
Write-Host "Done."
