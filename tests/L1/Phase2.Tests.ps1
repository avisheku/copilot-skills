$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

Describe 'Skills graph' {
    It 'validates' {
        (Test-SkillsGraph -Root $Root).Pass | Should -Be $true
    }
}

Describe 'MVP abidance' {
    It 'passes for all mvp skills' {
        $r = Test-AllSkillsAbidance -Root $Root | Where-Object { $_.Phase -eq 'mvp' }
        ($r | Where-Object { -not $_.Pass }).Count | Should -Be 0
    }
}

Describe 'Gate module' {
    It 'creates ShortPlan' {
        (New-ShortPlan -Goal 'x' -Steps @('a')).goal | Should -Be 'x'
    }
}
