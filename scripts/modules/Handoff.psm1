# Copilot Skills — handoff + session tokens

function Get-SessionPolicy {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-PackConfig -Name 'session-policy.json' -Root $Root
}

function Get-SessionTokenEstimate {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $entries = Get-LedgerEntries -Root $Root -Tail 500
    ($entries | Measure-Object -Property tokens_est -Sum).Sum
}

function Test-SessionTokenThreshold {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $policy = Get-SessionPolicy -Root $Root
$est = Get-SessionTokenEstimate -Root $Root
    if ($null -eq $est) { $est = 0 }
    [pscustomobject]@{
        Estimate  = $est
        SoftWarn  = $policy.tokenSoftWarn
        HardStop  = $policy.tokenHardStop
        Warn      = ($est -ge $policy.tokenSoftWarn)
        Stop      = ($est -ge $policy.tokenHardStop)
    }
}

function New-HandoffPack {
    param(
        [string]$Goal,
        [string[]]$CompletedSteps,
        [string[]]$RemainingSteps,
        [string[]]$OpenQuestions = @(),
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $pack = [ordered]@{
        type            = 'HandoffPack'
        goal            = $Goal
        completedSteps  = $CompletedSteps
        remainingSteps  = $RemainingSteps
        openQuestions   = $OpenQuestions
        ledgerPath      = (Get-LedgerPath -Root $Root)
        createdAt       = (Get-Date).ToUniversalTime().ToString('o')
    }
    $out = Join-Path $Root 'memory\.handoff-pack.json'
    $dir = Split-Path $out -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $pack | ConvertTo-Json -Depth 5 | Set-Content $out -Encoding utf8
    return $pack
}

function Save-McpSnapshot {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $mcp = Join-Path $Root '.mcp.json'
    $snap = Join-Path $Root 'memory\.mcp-snapshot.json'
    if (Test-Path $mcp) {
        Copy-Item $mcp $snap -Force
    }
    return $snap
}

function Restore-McpSnapshot {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $mcp = Join-Path $Root '.mcp.json'
    $snap = Join-Path $Root 'memory\.mcp-snapshot.json'
    if (Test-Path $snap) {
        Copy-Item $snap $mcp -Force
        return $true
    }
    Restore-McpMinimal -Root $Root | Out-Null
    return $false
}

Export-ModuleMember -Function Get-SessionPolicy, Get-SessionTokenEstimate, Test-SessionTokenThreshold, New-HandoffPack, Save-McpSnapshot, Restore-McpSnapshot
