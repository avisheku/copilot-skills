param([string]$InputJson = '{}')
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $root 'scripts\modules\CopilotSkills.psm1') -Force
try {
    $input = $InputJson | ConvertFrom-Json
    $text = if ($input.tool_input) { ($input.tool_input | ConvertTo-Json -Compress) } else { $InputJson }
    $guard = Get-PackConfig -Name 'guardrails.json' -Root $root
    foreach ($pat in $guard.dangerPatterns) {
        if ($text -like "*$pat*") {
            Write-LedgerEntry -Skill 'hook' -Tool 'danger-deny' -Outcome 'deny' -Root $root | Out-Null
            Write-Output '{"continue":false,"reason":"danger pattern blocked"}'
            exit 0
        }
    }
} catch { }
Write-Output '{"continue":true}'
