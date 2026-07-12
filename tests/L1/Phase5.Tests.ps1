$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

Describe 'Loop' {
    It 'runs one iteration' {
        (Invoke-LoopRun -MaxIterations 1 -Root $Root).Count | Should -Be 1
    }
}

Describe 'WireFormat' {
    It 'emits compact json envelope' {
        (ConvertTo-WireEnvelope -Payload @{ a = 1 } -Root $Root) | Should -Match 'compact-json'
    }
}

Describe 'Graph phase 5' {
    It 'includes loop and magic' {
        (Test-SkillsGraph -Root $Root).Pass | Should -Be $true
    }
}
