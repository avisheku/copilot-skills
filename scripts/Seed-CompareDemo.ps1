# Seed synthetic demo runs so leaderboard math is visible without live models.
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules\CopilotSkills.psm1') -Force

$runsDir = Join-Path $Root 'evidence\compare\runs'
if (Test-Path $runsDir) {
    Get-ChildItem $runsDir -Filter 'demo-*.json' -ErrorAction SilentlyContinue | Remove-Item -Force
}
New-Item -ItemType Directory -Force -Path $runsDir | Out-Null

# Fixed demo pairs: solo weaker/cheaper-looking vs harness better quality
$demos = @(
    @{ id='demo-01'; task='t01-clarify-scope'; arm='solo'; model='anthropic-opus'; tin=800; tout=400; q=0.45; lat=12000 }
    @{ id='demo-02'; task='t01-clarify-scope'; arm='harness-do'; model='anthropic-opus'; tin=1200; tout=500; q=0.95; lat=15000 }
    @{ id='demo-03'; task='t01-clarify-scope'; arm='solo'; model='anthropic-sonnet'; tin=700; tout=350; q=0.40; lat=8000 }
    @{ id='demo-04'; task='t01-clarify-scope'; arm='harness-do'; model='anthropic-sonnet'; tin=1100; tout=450; q=0.88; lat=9000 }
    @{ id='demo-05'; task='t07-moa-hard-judgment'; arm='solo'; model='anthropic-opus'; tin=2000; tout=900; q=0.55; lat=20000 }
    @{ id='demo-06'; task='t07-moa-hard-judgment'; arm='moa-lite'; model='anthropic-opus'; tin=5000; tout=1200; q=0.92; lat=45000 }
    @{ id='demo-07'; task='t04-2080-review'; arm='solo'; model='openai-gpt'; tin=600; tout=500; q=0.50; lat=7000 }
    @{ id='demo-08'; task='t04-2080-review'; arm='harness-2080'; model='openai-gpt'; tin=900; tout=600; q=0.90; lat=10000 }
    @{ id='demo-09'; task='t08-token-thrift'; arm='solo'; model='anthropic-sonnet'; tin=400; tout=800; q=0.70; lat=5000 }
    @{ id='demo-10'; task='t08-token-thrift'; arm='harness-do'; model='anthropic-sonnet'; tin=500; tout=300; q=0.85; lat=6000 }
)

foreach ($d in $demos) {
    $cost = Get-CompareEstimatedCostUsd -ModelId $d.model -TokensIn $d.tin -TokensOut $d.tout -Root $Root
    $rec = [ordered]@{
        runId = $d.id
        taskId = $d.task
        armId = $d.arm
        modelId = $d.model
        tokens_in = $d.tin
        tokens_out = $d.tout
        tokens_est = ($d.tin + $d.tout)
        latency_ms = $d.lat
        cost_usd = $cost
        quality = @{ passRate = $d.q; source = 'demo' }
        outputPath = $null
        notes = 'synthetic demo for Phase9 scoreboard'
        createdAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    $rec | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $runsDir "$($d.id).json") -Encoding utf8
}

Write-Host "Seeded $($demos.Count) demo runs into $runsDir"
Export-CompareReport -Root $Root | Out-Null
