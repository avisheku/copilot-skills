param([string]$InputJson = '{}')
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'scripts\modules\CopilotSkills.psm1') -Force
try {
    $input = $InputJson | ConvertFrom-Json
    $tool = if ($input.tool_name) { $input.tool_name } else { 'unknown' }
    $skill = if ($input.skill) { $input.skill } else { 'hook' }
    Write-LedgerEntry -Skill $skill -Tool $tool -Outcome 'ok' -Root $root | Out-Null
} catch {
    Write-LedgerEntry -Skill 'hook' -Tool 'ledger-error' -Outcome 'error' -Root $root | Out-Null
}
Write-Output '{"continue":true}'
