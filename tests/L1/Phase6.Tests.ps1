$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Import-Module (Join-Path $Root 'scripts\modules\CopilotSkills.psm1') -Force

Describe 'MoA' {
    It 'builds lite plan with three proposers' {
        (New-MoARunPlan -Query 'q' -ProfileId 'lite' -Root $Root).proposers.Count | Should -Be 3
    }
    It 'truncates long proposals' {
        $long = 'y' * 5000
        $p = New-MoAProposalPack -RunId 'testtrunc' -Proposals @(@{ id = 'a'; text = $long }) -Root $Root
        $p.Pack.proposals[0].chars | Should -BeLessOrEqual 1200
    }
}
