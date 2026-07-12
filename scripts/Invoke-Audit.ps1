param(
    [string]$Skill,
    [string]$Outcome,
    [string]$Session,
    [int]$Tail = 500,
    [switch]$Report,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

if ($Report) {
    $r = Invoke-AuditReport -Root $Root -Tail $Tail
    $r | ConvertTo-Json -Depth 5
    return $r
}

$hits = Search-Ledger -Skill $Skill -Outcome $Outcome -Session $Session -Root $Root -Tail $Tail
$hits | ConvertTo-Json -Depth 5
return $hits
