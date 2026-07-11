# Copilot Skills — description budget gate (~1500 chars)

function Get-SkillDescriptionBudget {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $policy = Get-PackConfig -Name 'session-policy.json' -Root $Root
    if ($policy.descriptionBudgetMax) { return [int]$policy.descriptionBudgetMax }
    return 1500
}

function Get-SkillsDescriptionTotal {
    param([string]$Root = (Get-CopilotSkillsRoot), [string]$SkillFilter)
    $skillsDir = Join-Path $Root 'skills'
    $total = 0
    Get-ChildItem $skillsDir -Directory | ForEach-Object {
        if ($SkillFilter -and $_.Name -ne $SkillFilter) { return }
        $skillMd = Join-Path $_.FullName 'SKILL.md'
        if (-not (Test-Path $skillMd)) { return }
        $raw = Get-Content $skillMd -Raw
        if ($raw -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
            $fm = $Matches[1]
            if ($fm -match '(?m)^description:\s*(.+)$') {
                $total += $Matches[1].Trim().Length
            }
        }
    }
    return $total
}

function Test-DescriptionBudget {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $max = Get-SkillDescriptionBudget -Root $Root
    $total = Get-SkillsDescriptionTotal -Root $Root
    [pscustomobject]@{
        Pass  = ($total -le $max)
        Total = $total
        Max   = $max
    }
}

Export-ModuleMember -Function Get-SkillDescriptionBudget, Get-SkillsDescriptionTotal, Test-DescriptionBudget
