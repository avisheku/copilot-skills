param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$evidenceDir = Join-Path $Root 'evidence'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

$steps = [System.Collections.Generic.List[object]]::new()
function Step($n, $cmd, $ok, $detail) {
    $script:steps.Add([ordered]@{ step = $n; command = $cmd; pass = $ok; detail = $detail })
}

# 1 Install
try {
    & (Join-Path $PSScriptRoot 'Install-CopilotSkills.ps1') -Target Copilot -Layer Folders | Out-Null
    Step 1 'Install-CopilotSkills' $true 'installed'
} catch { Step 1 'Install-CopilotSkills' $false $_.Exception.Message }

# 2 Sync check
try {
    Sync-CopilotSkillsTarget -Check -Target Copilot -Root $Root | Out-Null
    Step 2 'Sync -Check' $true 'in sync'
} catch { Step 2 'Sync -Check' $false $_.Exception.Message }

# 3 MCP minimal
try {
    Restore-McpMinimal -Root $Root | Out-Null
    Step 3 '/mcp minimal' $true 'minimal profile'
} catch { Step 3 '/mcp minimal' $false $_.Exception.Message }

# 4 Do prep (tiny /do)
try {
    $prep = & (Join-Path $PSScriptRoot 'Invoke-DoPrep.ps1') -Goal 'list repo top-level folders' -Root $Root
    Step 4 '/do prep' $true $prep.goal
} catch { Step 4 '/do prep' $false $_.Exception.Message }

# 5 2080 roles
try {
    $roles = (Get-PackConfig -Name '2080\roles.json' -Root $Root).roles
    Step 5 '/2080 roles' ($roles.Count -ge 4) ($roles -join ',')
} catch { Step 5 '/2080 roles' $false $_.Exception.Message }

# 6 Do finish + handoff
try {
    $fin = & (Join-Path $PSScriptRoot 'Invoke-DoFinish.ps1') -Goal 'golden path' -Completed @('prep') -Remaining @() -Root $Root
    Step 6 'handoff/restore' $fin.restored 'restored'
} catch { Step 6 'handoff/restore' $false $_.Exception.Message }

# 7 Ledger
$ledger = Get-LedgerPath -Root $Root
$hasLedger = Test-Path $ledger
Step 7 'ledger' $hasLedger $(if ($hasLedger) { 'exists' } else { 'missing' })

$allPass = (@($steps | Where-Object { -not $_.pass })).Count -eq 0
$evidence = [ordered]@{
    goldenPath = 'install -> mcp minimal -> do prep -> 2080 -> finish -> ledger'
    timestamp  = (Get-Date).ToUniversalTime().ToString('o')
    pass       = $allPass
    steps      = $steps
}
$out = Join-Path $evidenceDir 'golden-path.json'
$evidence | ConvertTo-Json -Depth 5 | Set-Content $out -Encoding utf8

if (-not $allPass) {
    Write-Host "Golden path FAILED. See $out"
    exit 1
}
Write-Host "Golden path PASSED. Evidence: $out"
exit 0
