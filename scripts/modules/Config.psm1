# Copilot Skills — config loader

function Get-PackConfig {
    param(
        [string]$Name,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $path = Join-Path $Root "config\$Name"
    if (-not (Test-Path $path)) { throw "Config not found: $path" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Get-PackConfigPath {
    param([string]$Name, [string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root "config\$Name"
}

Export-ModuleMember -Function Get-PackConfig, Get-PackConfigPath
