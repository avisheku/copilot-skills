$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

Describe 'Model tips' {
    It 'loads universal card' {
        (Get-ModelTipCard -Family universal -Root $Root).Length | Should -BeGreaterThan 0
    }
    It 'injects and restores' {
        Invoke-ModelTipInject -Root $Root | Should -Not -BeNullOrEmpty
        Restore-ModelState -Root $Root | Should -Be $true
    }
}

Describe 'Handoff' {
    It 'creates pack' {
        (New-HandoffPack -Goal 't' -CompletedSteps @('a') -RemainingSteps @() -Root $Root).type | Should -Be 'HandoffPack'
    }
}

Describe 'delegatesTo fixture' {
    It 'exists' {
        Test-Path (Join-Path $Root 'shared\fixtures\delegatesTo-research.json') | Should -Be $true
    }
}
