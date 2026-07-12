param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

# Phase 7 — L1 remainder + L2 fixtures + L3 static + schema + learn negative
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$fail = 0
function Assert($c, $m) { if (-not $c) { Write-Host "FAIL: $m"; $script:fail++ } else { Write-Host "OK: $m" } }

# --- L1: InstallSmoke already runs in Test-CI; re-check critical bits ---
$budget = Test-DescriptionBudget -Root $Root
Assert $budget.Pass "description budget $($budget.Total)/$($budget.Max)"
$hooks = Test-HooksManifest -Root $Root
Assert $hooks.Pass 'hooks.json valid'
$pack = Invoke-ContextPack -PackId 'default' -Root $Root
Assert ($pack.refs.Count -ge 1) 'context pack inject'
Restore-ContextDefault -Root $Root | Out-Null
Assert (-not (Test-Path (Get-StatePath -Root $Root))) 'context restore'

# --- Ledger schema ---
$entry = Write-LedgerEntry -Skill 'phase7' -Tool 'schema' -Outcome 'ok' -TokensEst 1 -Root $Root
$sch = Test-LedgerEntrySchema -Entry $entry -Root $Root
Assert $sch.Pass "ledger entry schema ($($sch.Issues -join '; '))"
$tail = Test-LedgerTailSchema -Root $Root -Tail 15
Assert $tail.Pass "ledger tail schema checked=$($tail.Checked)"

# --- Learn negative (byte shrink) ---
$big = Join-Path $env:TEMP 'learn-neg-target.txt'
$small = Join-Path $env:TEMP 'learn-neg-staging.txt'
(('x' * 220)) | Set-Content $big -NoNewline
(('y' * 40)) | Set-Content $small -NoNewline
$neg = Test-LearnUpgradeOnly -StagingPath $small -TargetPath $big -Root $Root
Assert (-not $neg.Pass) 'upgrade-only rejects shrink'

# --- Learn negative (marker drop on markdown) ---
$mdTarget = Join-Path $env:TEMP 'learn-neg-target.md'
$mdStaging = Join-Path $env:TEMP 'learn-neg-staging.md'
@"
# Title
## KEEP-SECTION
VERIFY: must stay
body padding padding padding padding padding padding
"@ | Set-Content $mdTarget
@"
# Title
VERIFY: must stay
padded body without KEEP-SECTION marker here lots of text to stay large enough xxxxxxxxxxxxxxxxxxxxxxxx
"@ | Set-Content $mdStaging
$negM = Test-LearnUpgradeOnly -StagingPath $mdStaging -TargetPath $mdTarget -Root $Root
Assert (-not $negM.Pass) 'upgrade-only rejects dropped markers'

# --- Golden path shape (requires prior GoldenPath gate) ---
$shape = Test-GoldenPathShape -Root $Root
Assert $shape.Pass "golden-path shape ($($shape.Issues -join '; '))"

# --- L2 fixtures ---
$l2 = Invoke-L2FixtureSuite -Root $Root
Assert $l2.Pass "L2 fixtures ($($l2.Issues -join '; '))"

# --- L2 promote gate ---
$gate = Invoke-L2PromoteGate -Root $Root
Assert $gate.Pass "L2 promote gate ($($gate.Issues -join '; '))"

# --- Handbook VERIFY intact (positive) ---
$hb = Get-Content (Join-Path $Root 'docs\HANDBOOK.md') -Raw
$hbOk = Test-HandbookVerifyIntact -BeforeText $hb -AfterText $hb
Assert $hbOk.Pass 'handbook VERIFY self-check'
$hbBad = Test-HandbookVerifyIntact -BeforeText $hb -AfterText "# empty`n"
Assert (-not $hbBad.Pass) 'handbook VERIFY detects wipe'

# --- Audit floors ---
$audit = Invoke-AuditReport -Root $Root
Assert ($audit.errorMapIds.Count -ge 3) "audit error-map ids ($($audit.errorMapIds.Count))"
Assert ($null -ne $audit.stats.Total) 'audit stats present'

# --- L3 static (signal; also merge-blocking structure for markers only) ---
$l3 = Test-L3StaticMarkers -Root $Root
Assert $l3.Pass "L3 static markers checked=$($l3.Checked) ($($l3.Issues -join '; '))"

if ($fail -gt 0) { exit 1 }
Write-Host "Phase 7: all passed."
exit 0
