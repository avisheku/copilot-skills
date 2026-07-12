# Copilot Skills — loop runner (reuses audit + 2080)

function Get-LoopConfig {
    param([string]$Root = (Get-CopilotSkillsRoot))
    Get-PackConfig -Name 'loop.json' -Root $Root
}

function Invoke-LoopIteration {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [int]$Iteration = 1
    )
    $cfg = Get-LoopConfig -Root $Root
    $results = [ordered]@{ iteration = $Iteration; steps = @() }

    foreach ($step in $cfg.steps) {
        switch ($step) {
            'audit' {
                $r = Invoke-AuditReport -Root $Root
                $results.steps += @{ step = 'audit'; errorCount = $r.errorCount; denyCount = $r.denyCount }
            }
            '2080' {
                $roles = (Get-PackConfig -Name '2080\roles.json' -Root $Root).roles
                $results.steps += @{ step = '2080'; roles = $roles; note = 'run /2080 in chat for synthesis' }
            }
            'moa' {
                $cmp = Compare-MoAToBaseline -Root $Root
                $results.steps += @{ step = 'moa'; compare = $cmp; note = 'run /moa in chat when recommendWire or for hard synth' }
            }
            default {
                $results.steps += @{ step = $step; skipped = $true }
            }
        }
    }
    Write-LedgerEntry -Skill 'loop' -Tool "iteration-$Iteration" -Outcome 'ok' -Root $Root | Out-Null
    return $results
}

function Invoke-LoopRun {
    param(
        [int]$MaxIterations = 0,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $cfg = Get-LoopConfig -Root $Root
    if (-not $cfg.enabled) {
        Write-Warning "loop.json enabled=false. One-shot iteration only."
    }
    $max = if ($MaxIterations -gt 0) { $MaxIterations } else { [int]$cfg.maxIterations }
    $out = @()
    for ($i = 1; $i -le $max; $i++) {
        $out += Invoke-LoopIteration -Root $Root -Iteration $i
    }
    return ,@($out)
}

Export-ModuleMember -Function Get-LoopConfig, Invoke-LoopIteration, Invoke-LoopRun
