param(
  [ValidateSet('Copilot','Claude','Cursor','All')]
  [string]$Target = 'Copilot',
  [ValidateSet('Auto','Plugin','Folders')]
  [string]$Layer = 'Auto',
  [string]$Skill
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Write-Host "Install-CopilotSkills: Target=$Target Layer=$Layer Root=$Root"
Write-Host "Phase 1: full install logic pending. See docs/HANDBOOK.md"

# Layer B stub: copy skills to user folder
$dest = Join-Path $env:USERPROFILE '.copilot\skills'
if ($Target -in @('Copilot','All')) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  $skillsSrc = Join-Path $Root 'skills'
  if (Test-Path $skillsSrc) {
    Get-ChildItem $skillsSrc -Directory | ForEach-Object {
      $skillDest = Join-Path $dest $_.Name
      if (Test-Path $skillDest) { Remove-Item $skillDest -Recurse -Force }
      Copy-Item $_.FullName $skillDest -Recurse -Force
      Write-Host "  copied $($_.Name) -> $skillDest"
    }
  }
}
Write-Host "Done."
