# Copilot Skills — install logic

function Resolve-InstallLayer {
    param(
        [ValidateSet('Auto','Plugin','Folders')][string]$Layer,
        [ValidateSet('Copilot','Claude','Cursor')][string]$Target
    )
    if ($Layer -ne 'Auto') { return $Layer }
    if ($Target -eq 'Copilot') {
        $settings = Join-Path $env:APPDATA 'Code\User\settings.json'
        if (Test-Path $settings) {
            $json = Get-Content $settings -Raw | ConvertFrom-Json
            if ($json.'chat.plugins.enabled' -eq $true) { return 'Plugin' }
        }
    }
    return 'Folders'
}

function Install-SkillFolder {
    param(
        [string]$SourceDir,
        [string]$DestRoot,
        [string]$SkillName
    )
    New-Item -ItemType Directory -Force -Path $DestRoot | Out-Null
    $dest = Join-Path $DestRoot $SkillName
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $SourceDir $dest -Recurse -Force
    return $dest
}

function Install-CopilotSkillsTarget {
    param(
        [ValidateSet('Copilot','Claude','Cursor')][string]$Target,
        [ValidateSet('Auto','Plugin','Folders')][string]$Layer,
        [string]$Skill,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $resolved = Resolve-InstallLayer -Layer $Layer -Target $Target
    $skillsSrc = Join-Path $Root 'skills'
    $destRoot = Get-TargetSkillPath -Target $Target
    $installed = @()

    if ($resolved -eq 'Plugin') {
        Write-Warning "Layer Plugin: register repo path in VS Code (see docs/HANDBOOK.md). Syncing skills folders as fallback."
    }

    $dirs = if ($Skill) {
        @(Get-Item (Join-Path $skillsSrc $Skill))
    } else {
        Get-ChildItem $skillsSrc -Directory
    }

    foreach ($d in $dirs) {
        $path = Install-SkillFolder -SourceDir $d.FullName -DestRoot $destRoot -SkillName $d.Name
        $installed += $path
        Write-Host "  installed $($d.Name) -> $path"
    }

    $hooksSrc = Join-Path $Root 'hooks'
    $hooksDest = Get-TargetHooksPath -Target $Target
    if (Test-Path $hooksSrc) {
        New-Item -ItemType Directory -Force -Path $hooksDest | Out-Null
        Copy-Item (Join-Path $hooksSrc '*') $hooksDest -Recurse -Force
        Write-Host "  hooks -> $hooksDest"
    }

    return [pscustomobject]@{ Layer = $resolved; Target = $Target; Installed = $installed }
}

Export-ModuleMember -Function Resolve-InstallLayer, Install-SkillFolder, Install-CopilotSkillsTarget
