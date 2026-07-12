param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

# Single CI entrypoint — fail fast on first gate failure
$ErrorActionPreference = 'Stop'
Set-Location $Root

$gates = @(
    @{ Name = 'InstallSmoke'; Script = 'scripts\Test-InstallSmoke.ps1' },
    @{ Name = 'Phase2'; Script = 'scripts\Test-Phase2.ps1' },
    @{ Name = 'GoldenPath'; Script = 'scripts\Test-GoldenPath.ps1' },
    @{ Name = 'Phase4'; Script = 'scripts\Test-Phase4.ps1' },
    @{ Name = 'Phase5'; Script = 'scripts\Test-Phase5.ps1' },
    @{ Name = 'Phase6'; Script = 'scripts\Test-Phase6.ps1' },
    @{ Name = 'Phase7'; Script = 'scripts\Test-Phase7.ps1' },
    @{ Name = 'Phase8'; Script = 'scripts\Test-Phase8.ps1' },
    @{ Name = 'Phase9'; Script = 'scripts\Test-Phase9.ps1' }
)

$failed = @()
foreach ($g in $gates) {
    Write-Host ""
    Write-Host "======== GATE: $($g.Name) ========"
    & (Join-Path $Root $g.Script) -Root $Root
    $code = $LASTEXITCODE
    if ($null -eq $code) { $code = 0 }
    if ($code -ne 0) {
        $failed += $g.Name
        Write-Host "FAIL: $($g.Name) exit $code"
        break
    }
    Write-Host "PASS: $($g.Name)"
}

# Always try dashboard after gates (even on failure if some evidence exists)
try {
    & (Join-Path $Root 'scripts\Export-LocalDashboard.ps1') -Root $Root | Out-Null
} catch {
    Write-Host "WARN: dashboard export failed: $($_.Exception.Message)"
}

if ($failed.Count -gt 0) {
    Write-Host "CI FAILED: $($failed -join ', ')"
    exit 1
}

Write-Host "CI PASSED: all gates green."
Write-Host "Dashboard: $(Join-Path $Root 'evidence\dashboard.html')"
exit 0
