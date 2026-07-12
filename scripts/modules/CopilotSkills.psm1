$ModuleRoot = $PSScriptRoot
$modules = @(
    'Paths', 'Config', 'Obs', 'Budget', 'ContextPack', 'McpProfile',
    'InstallLogic', 'SyncLogic', 'Abidance', 'Caveman', 'HookPayloads',
    'Gate', 'Graph', 'Models', 'Handoff', 'Schema', 'Governance', 'Quality',
    'Learn', 'Stats', 'Loop', 'WireFormat', 'MoA'
)
foreach ($m in $modules) {
    Import-Module (Join-Path $ModuleRoot "$m.psm1") -Force -Global
}

function Get-ImportedCopilotSkillsModules {
    return $modules
}

Export-ModuleMember -Function Get-ImportedCopilotSkillsModules
