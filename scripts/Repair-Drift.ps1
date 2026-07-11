param([switch]$WhatIf, [ValidateSet('Copilot','Claude','Cursor')][string]$Target = 'Copilot')

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$drift = Sync-CopilotSkillsTarget -Check -Target $Target -Root $Root
$outOfSync = $drift | Where-Object { -not $_.InSync }
if (-not $outOfSync) { Write-Host "No drift."; return }

foreach ($d in $outOfSync) {
    Write-Host "Repair: $($d.Skill)"
    if (-not $WhatIf) {
        & (Join-Path $PSScriptRoot 'Sync-CopilotSkills.ps1') -Skill $d.Skill -Target $Target
    }
}
