# Write/update evidence/quality-baseline.json after intentional green upgrades.
# Usage: .\scripts\Update-QualityBaseline.ps1

param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force
$path = Save-QualityBaseline -Root $Root
$suite = Invoke-InstructionQualitySuite -Root $Root
Write-Host "Baseline written: $path"
Write-Host "Score=$($suite.Score) casesVersion=$($suite.CasesVersion)"
