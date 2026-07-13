param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Strict
)

# Pillar 7 — lightweight secrets/PII path audit before push (constitution remediation C7)
$ErrorActionPreference = 'Stop'
$denyName = @(
    '\.env$', '\.pem$', '\.p12$', 'credentials\.json$', 'secrets\.json$',
    'id_rsa', '\.pfx$'
)
$denyPath = @(
    '[\\/]secrets[\\/]', '[\\/]data[\\/]', '\.db$'
)

$bad = New-Object System.Collections.Generic.List[string]
$files = @(git -C $Root ls-files)
foreach ($f in $files) {
    foreach ($pat in $denyName) {
        if ($f -match $pat) { [void]$bad.Add("name:$f") }
    }
    foreach ($pat in $denyPath) {
        if ($f -match $pat) { [void]$bad.Add("path:$f") }
    }
}

if ($bad.Count -gt 0) {
    Write-Host "FAIL: secrets-audit found $($bad.Count) risk path(s):"
    $bad | Select-Object -First 20 | ForEach-Object { Write-Host "  $_" }
    if ($Strict) { exit 1 }
    exit 1
}

Write-Host 'OK: secrets-audit clean (tracked files).'
exit 0
