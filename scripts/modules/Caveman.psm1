# Copilot Skills — caveman merge

function Get-CavemanConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $levelsPath = Join-Path $Root 'config\caveman\levels.json'
    $globalPath = Join-Path $Root 'config\caveman\global.md'
    @{
        Levels = if (Test-Path $levelsPath) { Get-Content $levelsPath -Raw | ConvertFrom-Json } else { $null }
        Global = if (Test-Path $globalPath) { Get-Content $globalPath -Raw } else { '' }
    }
}

function Get-CavemanBrief {
    param(
        [ValidateSet('lite','full','ultra')][string]$Level = 'lite',
        [string]$SkillId,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-CavemanConfig -Root $Root
    $skillPath = Join-Path $Root "skills\$SkillId\caveman.md"
    $skill = if (Test-Path $skillPath) { Get-Content $skillPath -Raw } else { '' }
    return @{ level = $Level; global = $cfg.Global; skill = $skill }
}

Export-ModuleMember -Function Get-CavemanConfig, Get-CavemanBrief
