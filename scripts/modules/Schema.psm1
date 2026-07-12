# Copilot Skills — JSON schema helpers (lightweight, no external deps)

function Test-LedgerEntrySchema {
    param(
        [Parameter(Mandatory)]$Entry,
        [string]$Root = (Get-CopilotSkillsRoot)
    )
    $issues = [System.Collections.Generic.List[string]]::new()
    function Get-EntryProp([object]$Obj, [string]$Name) {
        if ($null -eq $Obj) { return $null }
        if ($Obj -is [System.Collections.IDictionary]) {
            if ($Obj.Contains($Name)) { return $Obj[$Name] }
            return $null
        }
        return $Obj.$Name
    }
    $required = @('ts', 'session', 'skill', 'outcome')
    foreach ($k in $required) {
        $v = Get-EntryProp $Entry $k
        if ($null -eq $v -or [string]::IsNullOrWhiteSpace([string]$v)) {
            $issues.Add("missing required: $k")
        }
    }
    $outcome = Get-EntryProp $Entry 'outcome'
    $allowed = @('ok', 'warn', 'deny', 'error')
    if ($outcome -and ($allowed -notcontains [string]$outcome)) {
        $issues.Add("invalid outcome: $outcome")
    }
    [pscustomobject]@{ Pass = ($issues.Count -eq 0); Issues = @($issues) }
}

function Test-LedgerTailSchema {
    param(
        [string]$Root = (Get-CopilotSkillsRoot),
        [int]$Tail = 20
    )
    $entries = @(Get-LedgerEntries -Root $Root -Tail $Tail)
    $bad = @()
    foreach ($e in $entries) {
        $r = Test-LedgerEntrySchema -Entry $e -Root $Root
        if (-not $r.Pass) { $bad += @{ entry = $e; issues = $r.Issues } }
    }
    [pscustomobject]@{
        Pass    = ($bad.Count -eq 0)
        Checked = $entries.Count
        Bad     = $bad
    }
}

Export-ModuleMember -Function Test-LedgerEntrySchema, Test-LedgerTailSchema
