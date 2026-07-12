$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

Describe 'Learn module' {
    It 'lists error-map entries' {
        (Get-ErrorMapEntries -Root $Root).Count | Should -BeGreaterOrEqual 3
    }
}

Describe 'Stats module' {
    It 'returns ledger stats object' {
        (Get-LedgerStats -Root $Root).Total | Should -BeGreaterOrEqual 0
    }
}

Describe 'Audit module' {
    It 'generates report' {
        (Invoke-AuditReport -Root $Root).errorMapIds.Count | Should -BeGreaterOrEqual 3
    }
}
