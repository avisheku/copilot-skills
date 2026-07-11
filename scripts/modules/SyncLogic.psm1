# Copilot Skills — sync + drift check

function Get-DirectoryHash {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return '' }
    $files = Get-ChildItem $Path -Recurse -File | Sort-Object FullName
    $sb = [System.Text.StringBuilder]::new()
    foreach ($f in $files) {
        [void]$sb.AppendLine($f.FullName.Substring($Path.Length))
        [void]$sb.AppendLine((Get-FileHash $f.FullName -Algorithm SHA256).Hash)
    }
    if ($sb.Length -eq 0) { return '' }
    return (Get-FileHash -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($sb.ToString()))) -Algorithm SHA256).Hash
}

function Test-SkillDrift {
    param(
        [string]$SkillName,
        [string]$Root = (Get-CopilotSkillsRoot),
        [ValidateSet('Copilot','Claude','Cursor')][string]$Target = 'Copilot'
    )
    $src = Join-Path $Root "skills\$SkillName"
    $dest = Join-Path (Get-TargetSkillPath -Target $Target) $SkillName
    $srcHash = Get-DirectoryHash -Path $src
    $destHash = Get-DirectoryHash -Path $dest
    [pscustomobject]@{
        Skill    = $SkillName
        InSync   = ($srcHash -eq $destHash -and $srcHash -ne '')
        SrcHash  = $srcHash
        DestHash = $destHash
        Dest     = $dest
    }
}

function Sync-CopilotSkillsTarget {
    param(
        [switch]$Check,
        [string]$Skill,
        [ValidateSet('Copilot','Claude','Cursor')][string]$Target = 'Copilot',
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $skills = if ($Skill) { @($Skill) } else { (Get-ChildItem (Join-Path $Root 'skills') -Directory).Name }
    $results = foreach ($s in $skills) {
        if ($Check) {
            Test-SkillDrift -SkillName $s -Root $Root -Target $Target
        } else {
            $drift = Test-SkillDrift -SkillName $s -Root $Root -Target $Target
            if (-not $drift.InSync) {
                Install-SkillFolder -SourceDir (Join-Path $Root "skills\$s") `
                    -DestRoot (Get-TargetSkillPath -Target $Target) -SkillName $s | Out-Null
                Test-SkillDrift -SkillName $s -Root $Root -Target $Target
            } else { $drift }
        }
    }
    return $results
}

Export-ModuleMember -Function Get-DirectoryHash, Test-SkillDrift, Sync-CopilotSkillsTarget
