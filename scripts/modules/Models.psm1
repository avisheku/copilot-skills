# Copilot Skills — model-aware tips

function Get-ModelMatrix {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\models\matrix.json'
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-ModelTipCard {
    param(
        [string]$Family = 'universal',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $matrix = Get-ModelMatrix -Root $Root
    $fam = $matrix.families.$Family
    if (-not $fam) { $fam = $matrix.families.universal }
    $cardPath = Join-Path $Root "config\models\$($fam.tipCard)"
    if (-not (Test-Path $cardPath)) { return '' }
    return Get-Content $cardPath -Raw
}

function Save-ModelState {
    param(
        [string]$ActiveFamily = 'universal',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $statePath = Join-Path $Root 'memory\.model-state.json'
    $dir = Split-Path $statePath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    @{
        activeFamily = $ActiveFamily
        savedAt      = (Get-Date).ToUniversalTime().ToString('o')
        tipInjected  = $false
    } | ConvertTo-Json | Set-Content $statePath -Encoding utf8
}

function Invoke-ModelTipInject {
    param(
        [string]$Family = 'universal',
        [string]$Task = 'implement',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $matrix = Get-ModelMatrix -Root $Root
    $tier = $matrix.taskTiers.$Task
    if (-not $tier) { $tier = $matrix.defaultTier }
    $tips = Get-ModelTipCard -Family $Family -Root $Root
    $statePath = Join-Path $Root 'memory\.model-state.json'
    @{
        family    = $Family
        task      = $Task
        tier      = $tier
        tips      = $tips
        injectedAt = (Get-Date).ToUniversalTime().ToString('o')
    } | ConvertTo-Json -Depth 3 | Set-Content $statePath -Encoding utf8
    return @{ family = $Family; tips = $tips }
}

function Restore-ModelState {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $statePath = Join-Path $Root 'memory\.model-state.json'
    if (Test-Path $statePath) { Remove-Item $statePath -Force }
    return $true
}

Export-ModuleMember -Function Get-ModelMatrix, Get-ModelTipCard, Save-ModelState, Invoke-ModelTipInject, Restore-ModelState
