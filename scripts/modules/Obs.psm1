# Copilot Skills — JSONL ledger

function Write-LedgerEntry {
    param(
        [string]$Skill,
        [string]$Tool = '',
        [ValidateSet('ok','warn','deny','error')][string]$Outcome = 'ok',
        [int]$TokensEst = 0,
        [string]$Session = $env:COPILOT_SKILLS_SESSION,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $ledger = Get-LedgerPath -Root $Root
    $dir = Split-Path $ledger -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $entry = [ordered]@{
        ts         = (Get-Date).ToUniversalTime().ToString('o')
        session    = if ($Session) { $Session } else { [guid]::NewGuid().ToString('n').Substring(0, 8) }
        skill      = $Skill
        tool       = $Tool
        outcome    = $Outcome
        tokens_est = $TokensEst
    }
    ($entry | ConvertTo-Json -Compress) | Add-Content -Path $ledger -Encoding utf8
    return $entry
}

function Get-LedgerEntries {
    param([string]$Root = (Get-CopilotSkillsRoot), [int]$Tail = 100)
    $ledger = Get-LedgerPath -Root $Root
    if (-not (Test-Path $ledger)) { return @() }
    return Get-Content $ledger -Tail $Tail | ForEach-Object { $_ | ConvertFrom-Json }
}

Export-ModuleMember -Function Write-LedgerEntry, Get-LedgerEntries
