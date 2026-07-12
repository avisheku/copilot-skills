---
name: upgrade
description: Scan pack components + frontier watchlist; research upgrades; stage via /learn.
disable-model-invocation: true
---

# /upgrade

Keep the harness current with AI pace — **inventory locally**, **research with the agent**, **promote via upgrade-only `/learn`**.

## Procedure

1. **Scan (deterministic)**
   ```powershell
   .\scripts\Invoke-UpgradeScan.ps1
   # evidence\upgrade\report.md + report.json
   ```
2. **Research (agent)** — for each `status=review|action` and each frontier checklist item in the report, open watch URLs / news; note new, outdated, deprecated.
3. **Propose** — concrete file changes (tips, SOURCES, DEFER, skills, MoA, CI).
4. **Stage** — `/learn` upgrade-only; never silent overwrite.
5. **Verify** — `.\scripts\Test-CI.ps1` then promote + dual sync if skills.

## Covers

| Area | Examples |
|------|----------|
| Tech | CI Actions, hooks COMPAT, graph, MoA profiles |
| Instructions | HANDBOOK, gate-flow, SKILL.md contracts |
| Models | tip cards, matrix catalog URLs |
| Sources | `config/research/sources.json`, SOURCES.md |
| Frontier | AI news / agent eval / harness research topics |

## Policy

No auto-scrape on install. Explicit `/upgrade` or `/learn -Sources` only (ADR).
