param(
  [ValidateSet('Copilot','Claude','Cursor','All')]
  [string]$Target = 'Copilot',
  [string]$Skill
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$targets = if ($Target -eq 'All') { @('Copilot','Claude','Cursor') } else { @($Target) }
foreach ($t in $targets) {
    $destRoot = Get-TargetSkillPath -Target $t
    if ($Skill) {
        $p = Join-Path $destRoot $Skill
        if (Test-Path $p) { Remove-Item $p -Recurse -Force; Write-Host "removed $p" }
    } else {
        if (Test-Path $destRoot) {
            Remove-Item $destRoot -Recurse -Force
            Write-Host "removed $destRoot"
        }
    }
}
Write-Host "Done."
