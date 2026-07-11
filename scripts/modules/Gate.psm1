# Copilot Skills — dual-gate helpers

function Get-GatePhases {
    @(
        @{ id = 'clarify'; label = 'Clarify intent before research' }
        @{ id = 'research'; label = 'Research depth one' }
        @{ id = 'reclarify'; label = 'Clarify after research if needed' }
        @{ id = 'confirm'; label = 'ShortPlan user confirm' }
        @{ id = 'implement'; label = 'Execute after yes' }
        @{ id = 'finish'; label = '2080 + handoff if needed' }
    )
}

function New-ShortPlan {
    param(
        [string]$Goal,
        [string[]]$Steps,
        [string[]]$OutOfScope = @(),
        [string[]]$Risks = @()
    )
    [ordered]@{
        type        = 'ShortPlan'
        goal        = $Goal
        steps       = $Steps
        outOfScope  = $OutOfScope
        risks       = $Risks
        confirmed   = $false
        createdAt   = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function New-FullPlan {
    param(
        [string]$Goal,
        [object[]]$Steps,
        [string]$SkillId = 'do',
        [string[]]$DelegatesTo = @()
    )
    [ordered]@{
        id          = [guid]::NewGuid().ToString('n')
        type        = 'FullPlan'
        goal        = $Goal
        confirmed   = $false
        skillId     = $SkillId
        delegatesTo = $DelegatesTo
        steps       = $Steps
        createdAt   = (Get-Date).ToUniversalTime().ToString('o')
    }
}

function Confirm-Plan {
    param([psobject]$Plan)
    if ($Plan.PSObject.Properties['confirmed']) {
        $Plan.confirmed = $true
    }
    return $Plan
}

function Test-PlanConfirmed {
    param([psobject]$Plan)
    return ($Plan.confirmed -eq $true)
}

Export-ModuleMember -Function Get-GatePhases, New-ShortPlan, New-FullPlan, Confirm-Plan, Test-PlanConfirmed
