# Deferred (pain only)

Phase 5–8 shipped lean extensions. Still **not built** until measured need:

| Item | Why deferred |
|------|----------------|
| VSIX / Layer C | Org plugin or Layer B sufficient |
| Firm pack | No multi-tenant demand yet |
| OTel / SaaS obs | Local JSONL + HTML dashboard enough |
| Graphify | No graph UI pain yet |
| REST UI | Scripts + HANDBOOK + local dashboard enough |
| Custom MCP product | Explicit `/mcp` profiles enough |
| Marketplace | O7: local/git only |
| TOON wire | `wire.json` toonEnabled=false until measured |
| Auto-scrape sources | `/learn -Sources` on ask only |
| 2080 auto-apply | User confirm required |
| Deep Cursor | Best-effort COMPAT only |
| LLM-as-judge as required merge gate | Optional `quality-judge.yml` only; ICS is merge gate |
| Copilot-session / agentskills with_skill evals | Cost + flake; DEFER |

## Phase 5 shipped

- `/loop` + `Invoke-Loop.ps1`
- `/magic` alias → `/2080`
- `config/research/depth.json` (default depth 1)
- `WireFormat.psm1` compact JSON envelope
- Linux `scripts/linux/*.sh` wrappers
- L3 eval stub → filled in Phase 7

## Phase 6 shipped (lean MoA)

- `/moa` MoA-Lite — see `docs/plan/PHASE6_MOA.md`
- Still DEFER: dense 3+ MoA layers, Faster-MoA tree/early-exit serving, auto-wire into `/do` without stats

## Phase 7 shipped (governance)

- L1 InstallSmoke in CI · Phase7 schema/shape/negatives
- L2 fixtures + promote/handbook VERIFY gates
- Local `evidence/dashboard.html`
- Static L3 markers (LLM-judge still deferred as required)

## Phase 8 shipped (ICS)

- Instruction Contract Score vs baseline (`maxDrop`)
- Optional judge workflow (non-blocking)
- Still DEFER: required LLM judge, full Copilot-session harness

Enable remaining deferred items via `/learn` + ADR update when pain is proven.
