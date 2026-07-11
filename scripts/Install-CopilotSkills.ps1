param(
  [ValidateSet('Copilot','Claude','Cursor','All')]
  [string]$Target = 'Copilot',
  [ValidateSet('Auto','Plugin','Folders')]
  [string]$Layer = 'Auto',
  [string]$Skill
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

Write-Host "Install-CopilotSkills Root=$Root Target=$Target Layer=$Layer"

$budget = Test-DescriptionBudget -Root $Root
if (-not $budget.Pass) { throw "Description budget exceeded: $($budget.Total)/$($budget.Max)" }

$targets = if ($Target -eq 'All') { @('Copilot','Claude','Cursor') } else { @($Target) }
$results = foreach ($t in $targets) {
    Install-CopilotSkillsTarget -Target $t -Layer $Layer -Skill $Skill -Root $Root
}

Restore-McpMinimal -Root $Root | Out-Null
Write-Host "MCP profile: minimal"
Write-Host "Done."
return $results
