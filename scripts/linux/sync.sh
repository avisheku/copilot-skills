#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoProfile -File "$ROOT/scripts/Sync-CopilotSkills.ps1" "$@"
else
  echo "pwsh required"
  exit 1
fi
