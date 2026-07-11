# Copilot Skills — hook payload helpers

function Get-HooksManifest {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'hooks\hooks.json'
    if (-not (Test-Path $path)) { throw "hooks.json not found" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Test-HooksManifest {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $issues = @()
    try {
        $m = Get-HooksManifest -Root $Root
        if (-not $m.hooks) { $issues += 'missing hooks array' }
        foreach ($h in $m.hooks) {
            if (-not $h.event) { $issues += 'hook missing event' }
            if (-not $h.command) { $issues += "hook $($h.event) missing command" }
        }
    } catch {
        $issues += $_.Exception.Message
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = $issues }
}

function New-HookLedgerPayload {
    param([string]$Skill, [string]$Tool, [string]$Outcome = 'ok')
    @{
        skill   = $Skill
        tool    = $Tool
        outcome = $Outcome
    }
}

Export-ModuleMember -Function Get-HooksManifest, Test-HooksManifest, New-HookLedgerPayload
