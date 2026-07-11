# COMPAT: when native agent hooks unavailable, run guardrails manually before risky work.

param([string]$InputJson = '{}', [ValidateSet('secrets','danger','ledger','session')][string]$Hook = 'secrets')

$script = Join-Path $PSScriptRoot "run-$Hook.ps1"
if ($Hook -eq 'secrets') { $script = Join-Path $PSScriptRoot 'run-secrets-deny.ps1' }
if ($Hook -eq 'danger') { $script = Join-Path $PSScriptRoot 'run-danger-deny.ps1' }
if ($Hook -eq 'ledger') { $script = Join-Path $PSScriptRoot 'run-ledger.ps1' }
if ($Hook -eq 'session') { $script = Join-Path $PSScriptRoot 'run-session-stamp.ps1' }

& $script -InputJson $InputJson
