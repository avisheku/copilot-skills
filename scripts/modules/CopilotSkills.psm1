$ModuleRoot = $PSScriptRoot
$modules = @(
    'Paths', 'Config', 'Obs', 'Budget', 'ContextPack', 'McpProfile',
    'InstallLogic', 'SyncLogic', 'Abidance', 'Caveman', 'HookPayloads',
    'Gate', 'Graph', 'Models', 'Ladder', 'Handoff', 'Schema', 'Governance', 'Quality', 'Compare', 'Upgrade',
    'Learn', 'Stats', 'Loop', 'WireFormat', 'MoA'
)
foreach ($m in $modules) {
    Import-Module (Join-Path $ModuleRoot "$m.psm1") -Force -Global
}

function Get-ImportedCopilotSkillsModules {
    return $modules
}

Export-ModuleMember -Function Get-ImportedCopilotSkillsModules
