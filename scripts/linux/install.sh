#!/usr/bin/env bash
# Linux parity — requires PowerShell (pwsh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$ROOT/scripts/Install-CopilotSkills.ps1" "$@"
else
  echo "Install pwsh: https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-linux"
  exit 1
fi
