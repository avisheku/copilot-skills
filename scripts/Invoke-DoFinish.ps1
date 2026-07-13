param(
    [string]$Goal = 'session complete',
    [string[]]$Completed = @(),
    [string[]]$Remaining = @(),
    [string]$Blockers = '',
    [string]$NextAsk = '',
    [string]$TaskKind = 'implement',
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$thresh = Test-SessionTokenThreshold -Root $Root
$compacted = $null

# Soft warn → compact working memory (stay in session); hard stop → handoff for new chat
if ($thresh.Stop -or $thresh.Warn) {
    $compacted = Invoke-ContextCompact -Goal $Goal -CompletedSteps $Completed -RemainingSteps $Remaining `
        -Blockers $Blockers -NextAsk $NextAsk -TaskKind $TaskKind -SkipAsk -Root $Root
}

Restore-ContextDefault -Root $Root | Out-Null
Restore-ModelState -Root $Root | Out-Null
Restore-McpSnapshot -Root $Root | Out-Null
$pack = New-HandoffPack -Goal $Goal -CompletedSteps $Completed -RemainingSteps $Remaining -Root $Root
Write-LedgerEntry -Skill 'do' -Tool 'Invoke-DoFinish' -Outcome 'ok' -Root $Root | Out-Null

[pscustomobject]@{
    handoff    = $pack.type
    tokens     = $thresh
    compacted  = [bool]$compacted
    compactRef = if ($compacted) { $compacted.Pack.MdPath } else { $null }
    restored   = $true
    nextAction = if ($thresh.Stop) { 'new-chat-from-handoff' } elseif ($thresh.Warn) { 'continue-from-compact-or-handoff' } else { 'done' }
}
