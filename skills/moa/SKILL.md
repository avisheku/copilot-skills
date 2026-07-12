---
name: moa
description: Mixture of Agents — parallel cheaper proposers + aggregator synth for better quality/cost.
---

# /moa

Multi-model synthesis (MoA-Lite). Inspired by [togethercomputer/MoA](https://github.com/togethercomputer/moa) — **do not vendor**. Our config, packing, ledger.

## When to use

- Hard judgment / synthesis where one mid model is weak
- Want better quality than one mid model without always paying for top-tier alone
- Measure via ledger before wiring into `/do` or `/loop`

## Procedure

1. **Prep** — `.\scripts\Invoke-MoA.ps1 -Query "..." -Profile lite`
2. **Propose** — native fork `agents/moa-proposer.agent.md` once per proposer in plan (parallel). Different family tip cards.
3. **Pack** — `.\scripts\Invoke-MoAFinish.ps1 -RunId <id> -ProposalsJson '[...]'`
4. **Aggregate** — `agents/moa-aggregator.agent.md` with aggregator prompt file
5. **Ledger** — automatic; later `Compare-MoAToBaseline` decides wire-into-loop

## Profiles (`config/moa/profiles.json`)

| Profile | Shape |
|---------|--------|
| `lite` (default) | 3 proposers + mid aggregator |
| `full` | 4 proposers + stronger aggregator |
| `research` | research-oriented tip tasks |

## Rules

- Proposals truncated to `maxProposalChars` (context thrift)
- Min successful proposers from config
- Never invent paths; exact digits in code
- Do not auto-replace `/do` until stats recommend

## delegatesTo

None required. Optional later: from `/do` / `/research` / `/loop` when `Compare-MoAToBaseline.recommendWire` is true.
