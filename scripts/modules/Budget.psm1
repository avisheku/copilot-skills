# Copilot Skills — description budget gate (~1500 chars)

function Get-SkillDescriptionBudget {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $policy = Get-PackConfig -Name 'session-policy.json' -Root $Root
    if ($policy.descriptionBudgetMax) { return [int]$policy.descriptionBudgetMax }
    return 1500
}

function Get-SkillsDescriptionTotal {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [string]$SkillFilter,
        [switch]$MvpOnly
    )
    $skillsDir = Join-Path $Root 'skills'
    $total = 0
    Get-ChildItem $skillsDir -Directory | ForEach-Object {
        if ($SkillFilter -and $_.Name -ne $SkillFilter) { return }
        if ($MvpOnly) {
            $metaPath = Join-Path $_.FullName 'meta.json'
            if (Test-Path $metaPath) {
                $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
                if ($meta.phase -and $meta.phase -ne 'mvp') { return }
            }
        }
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
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [switch]$AllSkills
    )
    $max = Get-SkillDescriptionBudget -Root $Root
    # Default: MVP skills only (extensions like loop/magic/moa do not burn install budget)
    $total = if ($AllSkills) {
        Get-SkillsDescriptionTotal -Root $Root
    } else {
        Get-SkillsDescriptionTotal -Root $Root -MvpOnly
    }
    [pscustomobject]@{
        Pass  = ($total -le $max)
        Total = $total
        Max   = $max
        Scope = if ($AllSkills) { 'all' } else { 'mvp' }
    }
}

Export-ModuleMember -Function Get-SkillDescriptionBudget, Get-SkillsDescriptionTotal, Test-DescriptionBudget
