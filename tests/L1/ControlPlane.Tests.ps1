$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

Describe 'Description budget' {
    It 'is under max' {
        $b = Test-DescriptionBudget -Root $Root
        $b.Pass | Should -Be $true
    }
}

Describe 'Hooks manifest' {
    It 'is valid' {
        (Test-HooksManifest -Root $Root).Pass | Should -Be $true
    }
}

Describe 'Context pack' {
    It 'injects and restores' {
        Invoke-ContextPack -PackId 'default' -Root $Root | Should -Not -BeNullOrEmpty
        Restore-ContextDefault -Root $Root | Should -Be $true
        Test-Path (Get-StatePath -Root $Root) | Should -Be $false
    }
}

Describe 'Sync drift' {
    It 'detects after install' {
        Install-CopilotSkillsTarget -Target Copilot -Layer Folders -Root $Root | Out-Null
        $r = Sync-CopilotSkillsTarget -Check -Target Copilot -Root $Root
        ($r | Where-Object { -not $_.InSync }).Count | Should -Be 0
    }
}
