param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

if (-not (Get-Module -ListAvailable Pester)) {
    Write-Host "Pester not installed; running smoke only."
    & (Join-Path $PSScriptRoot '..\scripts\Test-InstallSmoke.ps1') -Root $Root
    exit $LASTEXITCODE
}

$config = New-PesterConfiguration
$config.Run.Path = @(
    (Join-Path $PSScriptRoot 'L1\ControlPlane.Tests.ps1'),
    (Join-Path $PSScriptRoot 'L1\Phase2.Tests.ps1')
)
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $config
if ($result.FailedCount -gt 0) { exit 1 }
