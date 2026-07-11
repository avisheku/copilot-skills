# Copilot Skills — abidance gate

function Test-AbidanceGate {
    param(
        [string]$SkillPath,
        [switch]$Strict
    )
    $issues = [System.Collections.Generic.List[string]]::new()
    $name = Split-Path $SkillPath -Leaf
    $metaPath = Join-Path $SkillPath 'meta.json'
    $phase = 'mvp'
    if (Test-Path $metaPath) {
        $meta = Get-Content $metaPath -Raw | ConvertFrom-Json
        if ($meta.phase) { $phase = $meta.phase }
    }

    if (-not (Test-Path (Join-Path $SkillPath 'SKILL.md'))) { $issues.Add('missing SKILL.md') }
    if (-not (Test-Path $metaPath)) { $issues.Add('missing meta.json') }

    $skillMd = Join-Path $SkillPath 'SKILL.md'
    if (Test-Path $skillMd) {
        $raw = Get-Content $skillMd -Raw
        if ($raw -notmatch '(?ms)^---\s*\r?\n.*?\r?\n---') { $issues.Add('SKILL.md missing frontmatter') }
    }

    if ($phase -eq 'mvp' -or $Strict) {
        foreach ($f in @('README.md', 'SETUP.md', 'ACCEPTANCE.md')) {
            if (-not (Test-Path (Join-Path $SkillPath $f))) { $issues.Add("missing $f") }
        }
    } elseif (-not (Test-Path (Join-Path $SkillPath 'README.md'))) {
        $issues.Add('missing README.md (recommended)')
    }

    [pscustomobject]@{
        Skill  = $name
        Phase  = $phase
        Pass   = ($issues.Count -eq 0)
        Issues = $issues
    }
}

function Test-AllSkillsAbidance {
    param([string]$Root = (Get-CopilotSkillsRoot), [switch]$Strict)
    Get-ChildItem (Join-Path $Root 'skills') -Directory | ForEach-Object {
        Test-AbidanceGate -SkillPath $_.FullName -Strict:$Strict
    }
}

function Invoke-CreateAbidanceGate {
    param([string]$SkillPath)
    $result = Test-AbidanceGate -SkillPath $SkillPath -Strict
    if (-not $result.Pass) {
        throw "Abidance gate failed for $($result.Skill): $($result.Issues -join '; ')"
    }
    return $result
}

Export-ModuleMember -Function Test-AbidanceGate, Test-AllSkillsAbidance, Invoke-CreateAbidanceGate
