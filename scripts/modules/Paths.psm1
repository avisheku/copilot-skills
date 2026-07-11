# Copilot Skills — path resolution (config over hardcode)

function Get-CopilotSkillsRoot {
    if ($env:COPILOT_SKILLS_HOME -and (Test-Path $env:COPILOT_SKILLS_HOME)) {
        return (Resolve-Path $env:COPILOT_SKILLS_HOME).Path
    }
    $here = $PSScriptRoot
    if ($here -match 'modules$') {
        return (Resolve-Path (Join-Path $here '..\..')).Path
    }
    return (Resolve-Path (Join-Path $here '..')).Path
}

function Get-TargetMap {
    @{
        Copilot = @{ Skills = Join-Path $env:USERPROFILE '.copilot\skills'; Hooks = Join-Path $env:USERPROFILE '.copilot\hooks' }
        Claude  = @{ Skills = Join-Path $env:USERPROFILE '.claude\skills'; Hooks = Join-Path $env:USERPROFILE '.claude\hooks' }
        Cursor  = @{ Skills = Join-Path $env:USERPROFILE '.cursor\skills'; Hooks = Join-Path $env:USERPROFILE '.cursor\hooks' }
    }
}

function Get-TargetSkillPath {
    param([ValidateSet('Copilot','Claude','Cursor')][string]$Target)
    $map = Get-TargetMap
    return $map[$Target].Skills
}

function Get-TargetHooksPath {
    param([ValidateSet('Copilot','Claude','Cursor')][string]$Target)
    $map = Get-TargetMap
    return $map[$Target].Hooks
}

function Get-LedgerPath {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'logs\ledger\events.jsonl'
}

function Get-StatePath {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Join-Path $Root 'memory\.context-state.json'
}

Export-ModuleMember -Function Get-CopilotSkillsRoot, Get-TargetMap, Get-TargetSkillPath, Get-TargetHooksPath, Get-LedgerPath, Get-StatePath
