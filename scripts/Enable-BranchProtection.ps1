# One-time: require CI green before merge to master
# Prerequisites: gh auth login; at least one successful CI run so check "PowerShell gates" exists
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
    required_pull_request_reviews = @{
        required_approving_review_count = 0
        dismiss_stale_reviews           = $true
    }
    restrictions       = $null
    allow_force_pushes = $false
    allow_deletions    = $false
} | ConvertTo-Json -Depth 6

$tmp = Join-Path $env:TEMP 'copilot-skills-branch-protection.json'
Set-Content -Path $tmp -Value $payload -Encoding utf8

Write-Host "Applying protection: $owner/$repo@$branch require '$checkName'"
gh api "repos/$owner/$repo/branches/$branch/protection" -X PUT --input $tmp
Write-Host "OK. Verify: https://github.com/$owner/$repo/settings/branches"
