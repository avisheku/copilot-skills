# Copilot Skills — MCP profile switch

function Get-McpProfiles {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\mcp\profiles.json'
    if (-not (Test-Path $path)) { throw "MCP profiles not found" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Set-McpProfile {
    param(
        [string]$ProfileId,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $profiles = Get-McpProfiles -Root $Root
    $match = $profiles.profiles | Where-Object { $_.id -eq $ProfileId } | Select-Object -First 1
    if (-not $match) { throw "MCP profile not found: $ProfileId" }
    $dest = Join-Path $Root '.mcp.json'
    $match.config | ConvertTo-Json -Depth 10 | Set-Content $dest -Encoding utf8
    $statePath = Join-Path $Root 'memory\.mcp-state.json'
    $stateDir = Split-Path $statePath -Parent
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Force -Path $stateDir | Out-Null }
    @{ active = $ProfileId; switchedAt = (Get-Date).ToUniversalTime().ToString('o') } |
        ConvertTo-Json | Set-Content $statePath -Encoding utf8
    return $match
}

function Restore-McpMinimal {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Set-McpProfile -ProfileId 'minimal' -Root $Root
}

Export-ModuleMember -Function Get-McpProfiles, Set-McpProfile, Restore-McpMinimal
