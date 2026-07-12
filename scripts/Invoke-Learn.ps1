param(
    [Parameter(Mandatory)][ValidateSet('setup','sync','arch','playbook','token-save','context-save','caveman','handbook-fix','handbook-install','handbook-skill','error-map')][string]$Kind,
    [Parameter(Mandatory)][string]$Title,
    [string]$Body = '',
    [string]$StagingFile,
    [string]$TargetFile,
    [switch]$Promote,
    [switch]$DualSync,
    [switch]$Handbook,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

if ($Kind -eq 'error-map') {
    throw 'Use New-ErrorMapEntry via module for error-map kind'
}

if ($Promote) {
    if (-not $StagingFile -or -not $TargetFile) { throw 'Promote requires -StagingFile and -TargetFile' }
    if ($Handbook) {
        return Invoke-LearnHandbookPatch -StagingFile $StagingFile -Root $Root
    }
    return Invoke-LearnPromote -StagingFile $StagingFile -TargetFile $TargetFile -DualSync:$DualSync -Root $Root
}

return New-LearnStaging -Kind $Kind -Title $Title -Body $Body -Root $Root
