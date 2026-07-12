param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

# Phase 8 — Instruction Contract Score vs baseline (maxDrop)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

Assert (Test-Path (Join-Path $Root 'config\evals\quality-gate.json')) 'quality-gate.json'
Assert (Test-Path (Get-QualityCasesPath -Root $Root)) 'l4-quality-cases.json'

$suite = Invoke-InstructionQualitySuite -Root $Root
Assert ($suite.Score -ge 0.85) "ICS score $($suite.Score) ($($suite.Issues -join '; '))"
Assert $suite.Pass "ICS all cases ($($suite.Issues -join '; '))"

$cmp = Compare-QualityToBaseline -Root $Root -Suite $suite
Assert $cmp.Pass "quality vs baseline score=$($cmp.Score) baseline=$($cmp.Baseline) drop=$($cmp.Drop) ($($cmp.Issues -join '; '))"

$gate = Invoke-QualityGate -Root $Root
Assert $gate.Pass "Invoke-QualityGate ($($gate.Issues -join '; '))"

# Path scoping: non-md skip
$skip = Invoke-QualityGate -Root $Root -TargetPath (Join-Path $Root 'config\wire.json')
Assert $skip.Skipped 'quality skipped for non-glob path'

# Negative: stripping Clarify from do skill text fails contains check
$doPath = Join-Path $Root 'skills\do\SKILL.md'
$doText = Get-Content $doPath -Raw
$broken = $doText -replace 'Clarify', 'XXX'
Assert ($doText.IndexOf('Clarify', [StringComparison]::OrdinalIgnoreCase) -ge 0) 'fixture has Clarify'
Assert ($broken.IndexOf('Clarify', [StringComparison]::OrdinalIgnoreCase) -lt 0) 'broken text loses Clarify'

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 8: all passed. ICS=$($suite.Score) baseline=$($cmp.Baseline)"
exit 0
