# Copilot Skills — context pack inject / restore

function Get-ContextPack {
    param([string]$PackId, [string]$Root = (Get-CopilotSkillsRoot))
    $packPath = Join-Path $Root "config\context-packs\$PackId.json"
    if (-not (Test-Path $packPath)) { throw "Context pack not found: $PackId" }
    return Get-Content $packPath -Raw | ConvertFrom-Json
}

function Invoke-ContextPack {
    param([string]$PackId, [string]$Root = (Get-CopilotSkillsRoot))
    $pack = Get-ContextPack -PackId $PackId -Root $Root
    $statePath = Get-StatePath -Root $Root
    $stateDir = Split-Path $statePath -Parent
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Force -Path $stateDir | Out-Null }

    $snapshot = @{ activePack = $PackId; injectedAt = (Get-Date).ToUniversalTime().ToString('o'); refs = @() }
    foreach ($ref in $pack.refs) {
        $full = Join-Path $Root $ref
        if (Test-Path $full) {
            $snapshot.refs += @{ path = $ref; content = (Get-Content $full -Raw) }
        }
    }
    $snapshot | ConvertTo-Json -Depth 5 | Set-Content $statePath -Encoding utf8
    return $snapshot
}

function Restore-ContextDefault {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $statePath = Get-StatePath -Root $Root
    if (Test-Path $statePath) { Remove-Item $statePath -Force }
    return $true
}

function Get-ActiveContextPack {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $statePath = Get-StatePath -Root $Root
    if (-not (Test-Path $statePath)) { return $null }
    return Get-Content $statePath -Raw | ConvertFrom-Json
}

Export-ModuleMember -Function Get-ContextPack, Invoke-ContextPack, Restore-ContextDefault, Get-ActiveContextPack
