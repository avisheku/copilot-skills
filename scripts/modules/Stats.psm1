# Copilot Skills — ledger stats + audit search

function Get-LedgerStats {
    param([string]$Root = (Get-CopilotSkillsRoot), [int]$Tail = 1000)
    $entries = @(Get-LedgerEntries -Root $Root -Tail $Tail)
    if ($entries.Count -eq 0) {
        return [pscustomobject]@{
            Total = 0; BySkill = @{}; ByOutcome = @{}; TokensEst = 0
        }
    }
    $bySkill = @{}
    $byOutcome = @{}
    $tokens = 0
    foreach ($e in $entries) {
        if (-not $bySkill.ContainsKey($e.skill)) { $bySkill[$e.skill] = 0 }
        $bySkill[$e.skill]++
        if (-not $byOutcome.ContainsKey($e.outcome)) { $byOutcome[$e.outcome] = 0 }
        $byOutcome[$e.outcome]++
        if ($e.tokens_est) { $tokens += [int]$e.tokens_est }
    }
    [pscustomobject]@{
        Total     = $entries.Count
        BySkill   = $bySkill
        ByOutcome = $byOutcome
        TokensEst = $tokens
        From      = $entries[0].ts
        To        = $entries[-1].ts
    }
}

function Search-Ledger {
    param(
        [string]$Skill,
        [string]$Outcome,
        [string]$Session,
        [string]$Root = (Get-CopilotSkillsRoot),
        [int]$Tail = 500
    )
    $entries = Get-LedgerEntries -Root $Root -Tail $Tail
    if ($Skill) { $entries = $entries | Where-Object { $_.skill -eq $Skill } }
    if ($Outcome) { $entries = $entries | Where-Object { $_.outcome -eq $Outcome } }
    if ($Session) { $entries = $entries | Where-Object { $_.session -eq $Session } }
    return $entries
}

function Invoke-AuditReport {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [int]$Tail = 500
    )
    $stats = Get-LedgerStats -Root $Root -Tail $Tail
    $errors = Search-Ledger -Outcome 'error' -Root $Root -Tail $Tail
    $denies = Search-Ledger -Outcome 'deny' -Root $Root -Tail $Tail
    $map = Get-ErrorMapEntries -Root $Root
    [pscustomobject]@{
        generatedAt = (Get-Date).ToUniversalTime().ToString('o')
        stats       = $stats
        errorCount  = $errors.Count
        denyCount   = $denies.Count
        errorMapIds = @($map | ForEach-Object { $_.id })
        recentErrors = @($errors | Select-Object -Last 10)
    }
}

Export-ModuleMember -Function Get-LedgerStats, Search-Ledger, Invoke-AuditReport
