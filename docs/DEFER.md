# Deferred (pain only)

Phase 5 shipped **lean** extensions. Still **not built** until measured need:

| Item | Why deferred |
|------|----------------|
| VSIX / Layer C | Org plugin or Layer B sufficient |
| Firm pack | No multi-tenant demand yet |
| OTel / SaaS obs | Local JSONL ledger enough |
| Graphify | No graph UI pain yet |
| REST UI | Scripts + HANDBOOK enough |
| Custom MCP product | Explicit `/mcp` profiles enough |
| Marketplace | O7: local/git only |
| TOON wire | `wire.json` toonEnabled=false until measured |
| Auto-scrape sources | `/learn -Sources` on ask only |
| 2080 auto-apply | User confirm required |
| Deep Cursor | Best-effort COMPAT only |

## Phase 5 shipped

- `/loop` + `Invoke-Loop.ps1`
- `/magic` alias → `/2080`
- `config/research/depth.json` (default depth 1)
- `WireFormat.psm1` compact JSON envelope
- Linux `scripts/linux/*.sh` wrappers
- L3 eval stub (`tests/evals/`)

## Phase 6 shipped (lean MoA)

- `/moa` MoA-Lite — see `docs/plan/PHASE6_MOA.md`
- Still DEFER: dense 3+ MoA layers, Faster-MoA tree/early-exit serving, auto-wire into `/do` without stats

Enable remaining deferred items via `/learn` + ADR update when pain is proven.
