# Copilot Skills — skills.graph.json validation

function Get-SkillsGraph {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $path = Join-Path $Root 'config\skills.graph.json'
    if (-not (Test-Path $path)) { throw "skills.graph.json not found" }
    return Get-Content $path -Raw | ConvertFrom-Json
}

function Test-SkillsGraph {
    param([string]$Root = (Get-CopilotSkillsRoot))
    $issues = [System.Collections.Generic.List[string]]::new()
    $graph = Get-SkillsGraph -Root $Root
    $skillsDir = Join-Path $Root 'skills'
    $known = @{}
    foreach ($s in $graph.skills) {
        if (-not $s.id) { $issues.Add('skill entry missing id'); continue }
        $known[$s.id] = $true
    }
    foreach ($s in $graph.skills) {
        if (-not $s.id) { continue }
        $folder = Join-Path $skillsDir $s.id
        if (-not (Test-Path $folder)) { $issues.Add("missing folder: skills/$($s.id)") }
        if ($s.delegatesTo) {
            foreach ($d in $s.delegatesTo) {
                if (-not $known.ContainsKey($d)) { $issues.Add("$($s.id) delegatesTo unknown: $d") }
            }
        }
    }
    Get-ChildItem $skillsDir -Directory | ForEach-Object {
        if (-not $known.ContainsKey($_.Name)) {
            $issues.Add("folder not in graph: $($_.Name)")
        }
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = $issues }
}

Export-ModuleMember -Function Get-SkillsGraph, Test-SkillsGraph
