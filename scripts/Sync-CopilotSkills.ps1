param(
  [switch]$Check,
  [string]$Skill,
  [ValidateSet('Copilot','Claude','Cursor','All')]
  [string]$Target = 'Copilot'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$targets = if ($Target -eq 'All') { @('Copilot','Claude','Cursor') } else { @($Target) }
$all = foreach ($t in $targets) {
    Sync-CopilotSkillsTarget -Check:$Check -Skill $Skill -Target $t -Root $Root
}

if ($Check) {
    $drift = $all | Where-Object { -not $_.InSync }
    if ($drift) {
        Write-Warning "Drift detected: $($drift.Skill -join ', ')"
        exit 1
    }
    Write-Host "All skills in sync."
}
Write-Host "Done."
return $all
