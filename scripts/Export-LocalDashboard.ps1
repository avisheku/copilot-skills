param(
    [int]$Tail = 1000,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$OutPath
)

# Self-contained local HTML dashboard for stats / CI / golden path
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

if (-not $OutPath) { $OutPath = Join-Path $Root 'evidence\dashboard.html' }
$evidenceDir = Split-Path $OutPath -Parent
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

$stats = Get-LedgerStats -Root $Root -Tail $Tail
$audit = Invoke-AuditReport -Root $Root -Tail $Tail
$goldenPath = Join-Path $Root 'evidence\golden-path.json'
$golden = $null
if (Test-Path $goldenPath) { $golden = Get-Content $goldenPath -Raw | ConvertFrom-Json }

$bySkillRows = @()
if ($stats.BySkill) {
    foreach ($k in @($stats.BySkill.Keys)) {
        $bySkillRows += "<tr><td>$([System.Net.WebUtility]::HtmlEncode($k))</td><td>$($stats.BySkill[$k])</td></tr>"
    }
}
$byOutcomeRows = @()
if ($stats.ByOutcome) {
    foreach ($k in @($stats.ByOutcome.Keys)) {
        $byOutcomeRows += "<tr><td>$([System.Net.WebUtility]::HtmlEncode($k))</td><td>$($stats.ByOutcome[$k])</td></tr>"
    }
}
$stepRows = ''
if ($golden -and $golden.steps) {
    foreach ($s in @($golden.steps)) {
        $cls = if ($s.pass) { 'ok' } else { 'bad' }
        $stepRows += "<tr class='$cls'><td>$($s.step)</td><td>$([System.Net.WebUtility]::HtmlEncode([string]$s.command))</td><td>$($s.pass)</td><td>$([System.Net.WebUtility]::HtmlEncode([string]$s.detail))</td></tr>"
    }
}
$errRows = ''
foreach ($e in @($audit.recentErrors)) {
    $errRows += "<tr><td>$([System.Net.WebUtility]::HtmlEncode([string]$e.ts))</td><td>$([System.Net.WebUtility]::HtmlEncode([string]$e.skill))</td><td>$([System.Net.WebUtility]::HtmlEncode([string]$e.tool))</td></tr>"
}
$mapIds = (@($audit.errorMapIds) | ForEach-Object { [System.Net.WebUtility]::HtmlEncode($_) }) -join ', '
$generated = (Get-Date).ToUniversalTime().ToString('o')
$goldenPass = if ($null -eq $golden) { 'n/a' } else { [string]$golden.pass }

$icsScore = 'n/a'
$icsBaseline = 'n/a'
$icsDrop = 'n/a'
$icsPass = 'n/a'
try {
    $cmp = Compare-QualityToBaseline -Root $Root
    $icsScore = [string]$cmp.Score
    $icsBaseline = if ($null -ne $cmp.Baseline) { [string]$cmp.Baseline } else { 'missing' }
    $icsDrop = if ($null -ne $cmp.Drop) { [string]$cmp.Drop } else { 'n/a' }
    $icsPass = if ($cmp.Pass) { 'pass' } else { 'fail' }
} catch {
    $icsPass = 'error'
}

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>Copilot Skills — Local Dashboard</title>
<style>
  body{font-family:Segoe UI,system-ui,sans-serif;margin:2rem;background:#0f1419;color:#e7ecf1}
  h1{font-size:1.4rem;margin:0 0 .25rem}
  .meta{color:#9aa7b5;margin-bottom:1.5rem}
  section{margin:1.5rem 0;padding:1rem 1.25rem;background:#1a2332;border-radius:8px}
  h2{font-size:1.05rem;margin:0 0 .75rem;color:#c5d4e4}
  table{border-collapse:collapse;width:100%;font-size:.9rem}
  th,td{text-align:left;padding:.4rem .5rem;border-bottom:1px solid #2a3648}
  th{color:#9aa7b5;font-weight:600}
  tr.ok td:nth-child(3){color:#3dd68c}
  tr.bad td:nth-child(3){color:#ff6b6b}
  .kpi{display:flex;gap:1rem;flex-wrap:wrap}
  .kpi div{background:#121a24;padding:.75rem 1rem;border-radius:6px;min-width:7rem}
  .kpi strong{display:block;font-size:1.4rem}
  .kpi span{color:#9aa7b5;font-size:.8rem}
</style>
</head>
<body>
  <h1>Copilot Skills — Local Dashboard</h1>
  <p class="meta">Generated $generated · Tail $Tail · Repo $([System.Net.WebUtility]::HtmlEncode($Root))</p>

  <section>
    <h2>KPIs</h2>
    <div class="kpi">
      <div><strong>$($stats.Total)</strong><span>Ledger events</span></div>
      <div><strong>$($stats.TokensEst)</strong><span>Tokens est</span></div>
      <div><strong>$($audit.errorCount)</strong><span>Errors</span></div>
      <div><strong>$($audit.denyCount)</strong><span>Denies</span></div>
      <div><strong>$goldenPass</strong><span>Golden path</span></div>
      <div><strong>$(@($audit.errorMapIds).Count)</strong><span>Error-map ids</span></div>
      <div><strong>$icsScore</strong><span>ICS score (deterministic)</span></div>
      <div><strong>$icsBaseline</strong><span>ICS baseline</span></div>
      <div><strong>$icsDrop</strong><span>ICS drop</span></div>
      <div><strong>$icsPass</strong><span>ICS gate</span></div>
    </div>
    <p class="meta" style="margin-top:.75rem">ICS = Instruction Contract Score — not live Copilot chat quality.</p>
  </section>

  <section>
    <h2>By skill</h2>
    <table><thead><tr><th>Skill</th><th>Count</th></tr></thead><tbody>
    $($bySkillRows -join "`n")
    </tbody></table>
  </section>

  <section>
    <h2>By outcome</h2>
    <table><thead><tr><th>Outcome</th><th>Count</th></tr></thead><tbody>
    $($byOutcomeRows -join "`n")
    </tbody></table>
  </section>

  <section>
    <h2>Golden path steps</h2>
    <table><thead><tr><th>#</th><th>Command</th><th>Pass</th><th>Detail</th></tr></thead><tbody>
    $stepRows
    </tbody></table>
  </section>

  <section>
    <h2>Error-map ids</h2>
    <p>$mapIds</p>
  </section>

  <section>
    <h2>Recent errors</h2>
    <table><thead><tr><th>ts</th><th>skill</th><th>tool</th></tr></thead><tbody>
    $errRows
    </tbody></table>
  </section>
</body>
</html>
"@

[System.IO.File]::WriteAllText($OutPath, $html)
Write-Host "Dashboard: $OutPath"
return $OutPath
