# One-time: require CI green before merge to master
# Prerequisites: gh auth login; repo public (or GitHub Pro); at least one successful CI run
# Usage: .\scripts\Enable-BranchProtection.ps1

$ErrorActionPreference = 'Stop'
$owner = 'avisheku'
$repo = 'copilot-skills'
$branch = 'master'
$checkName = 'PowerShell gates'

$payload = @{
    required_status_checks = @{
        strict   = $true
        contexts = @($checkName)
    }
    enforce_admins                = $false
    required_pull_request_reviews = $null
    restrictions                  = $null
    allow_force_pushes            = $false
    allow_deletions               = $false
} | ConvertTo-Json -Depth 6 -Compress

$tmp = Join-Path $env:TEMP 'copilot-skills-branch-protection.json'
[System.IO.File]::WriteAllText($tmp, $payload)

Write-Host "Applying protection: $owner/$repo@$branch require '$checkName'"
$out = gh api "repos/$owner/$repo/branches/$branch/protection" -X PUT --input $tmp 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host $out
    if ("$out" -match 'Upgrade to GitHub Pro|make this repository public') {
        Write-Host @"

BLOCKED: Free private repos cannot use branch protection.
Pick one:
  1) Make repo public, then re-run this script
  2) Upgrade to GitHub Pro, then re-run this script
  3) Soft gate: only merge when Actions check 'PowerShell gates' is green
See docs/CI.md
"@
    }
    exit 1
}
Write-Host "OK. Verify: https://github.com/$owner/$repo/settings/branches"
