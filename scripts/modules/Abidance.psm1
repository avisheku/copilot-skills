# Copilot Skills — abidance gate

function Test-AbidanceGate {
    param([string]$SkillPath)
    $issues = [System.Collections.Generic.List[string]]::new()
    $name = Split-Path $SkillPath -Leaf

    if (-not (Test-Path (Join-Path $SkillPath 'SKILL.md'))) { $issues.Add('missing SKILL.md') }
    if (-not (Test-Path (Join-Path $SkillPath 'README.md'))) { $issues.Add('missing README.md (recommended)') }

    $skillMd = Join-Path $SkillPath 'SKILL.md'
    if (Test-Path $skillMd) {
        $raw = Get-Content $skillMd -Raw
        if ($raw -notmatch '(?ms)^---\s*\r?\n.*?\r?\n---') { $issues.Add('SKILL.md missing frontmatter') }
    }

    [pscustomobject]@{
        Skill  = $name
        Pass   = ($issues.Count -eq 0 -or ($issues.Count -eq 1 -and $issues[0] -like 'missing README*'))
        Issues = $issues
    }
}

function Test-AllSkillsAbidance {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-ChildItem (Join-Path $Root 'skills') -Directory | ForEach-Object {
        Test-AbidanceGate -SkillPath $_.FullName
    }
}

Export-ModuleMember -Function Test-AbidanceGate, Test-AllSkillsAbidance
