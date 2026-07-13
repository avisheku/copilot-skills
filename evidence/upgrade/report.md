# Upgrade / frontier scan

Generated: 2026-07-13T06:12:50.5491971Z
Summary: action=0 review=3 ok=9 / 12

## Components
### pack-version (review)
- kind: meta Â· path: `docs/VERSIONS.md`
  - [info] review-pack-version: Confirm Pack version vs shipped phases
  - [info] watchlist: https://github.com/avisheku/copilot-skills/releases

### skills-graph (ok)
- kind: skills Â· path: `config/skills.graph.json`
  - [info] watchlist: https://agentskills.io | https://docs.github.com/copilot

### model-tips (review)
- kind: models Â· path: `config/models/matrix.json`
  - [info] research-model-tips: Research provider changelogs; update tip cards if APIs/prompting guidance changed
  - [info] watchlist: https://docs.anthropic.com | https://platform.openai.com/docs | https://ai.google.dev/docs

### moa (ok)
- kind: orchestration Â· path: `config/moa/profiles.json`
  - [info] watchlist: https://github.com/togethercomputer/moa | https://arxiv.org/abs/2406.04692

### ics-quality (ok)
- kind: governance Â· path: `config/evals/quality-gate.json`
  - [info] watchlist: https://www.promptfoo.dev/docs/integrations/ci-cd/

### compare-tracker (ok)
- kind: governance Â· path: `config/compare/arms.json`
  - [info] watchlist: https://arxiv.org/html/2605.27922 | https://lmarena.ai

### ci-actions (ok)
- kind: ci Â· path: `.github/workflows/ci.yml`
  - [info] watchlist: https://github.blog/changelog/ | https://docs.github.com/en/actions

### hooks-compat (ok)
- kind: runtime Â· path: `docs/COMPAT.md`
  - [info] watchlist: https://docs.github.com/copilot

### frontier-sources (review)
- kind: sources Â· path: `docs/SOURCES.md`
  - [info] frontier-pass: Agent: scan SOURCES + news URLs for new/deprecated items
  - [info] watchlist: https://agentskills.io | https://github.blog/changelog/ | https://openai.com/index/ | https://www.anthropic.com/news | https://deepmind.google/discover/blog/

### defer-backlog (ok)
- kind: roadmap Â· path: `docs/DEFER.md`

### handbook (ok)
- kind: instructions Â· path: `docs/HANDBOOK.md`

### gate-flow (ok)
- kind: instructions Â· path: `shared/instructions/gate-flow.md`
  - [info] watchlist: https://agentskills.io

## Frontier topics (research checklist)
- [ ] agent skills / SKILL.md standards
- [ ] Copilot hooks plugins fork
- [ ] model tip / prompting best practices (Anthropic OpenAI Google)
- [ ] MoA / multi-agent synthesis
- [ ] eval harnesses / prompt regression / ICS
- [ ] harness vs model performance (Harness-Bench)
- [ ] MCP tooling changes
- [ ] GitHub Actions / token / security changelog

## Research sources
- [Agent Skills](https://agentskills.io)
- [GitHub Copilot](https://docs.github.com/copilot)
- [Anthropic docs](https://docs.anthropic.com)
- [OpenAI docs](https://platform.openai.com/docs)
- [Google AI docs](https://ai.google.dev/docs)
- [Mixture-of-Agents](https://github.com/togethercomputer/moa)
- [MoA paper](https://arxiv.org/abs/2406.04692)
- [Harness-Bench](https://arxiv.org/html/2605.27922)
- [Harness Effect](https://arxiv.org/html/2607.06906)
- [Promptfoo CI](https://www.promptfoo.dev/docs/integrations/ci-cd/)
- [LMArena](https://lmarena.ai)
- [GitHub Changelog](https://github.blog/changelog/)
- [Anthropic news](https://www.anthropic.com/news)
- [OpenAI news](https://openai.com/index/)

## Next steps
1. For each status=action: fix locally or stage via /learn
2. For each status=review: agent researches watch URLs + frontierTopics
3. Promote instruction/model tip changes with upgrade-only /learn + CI
4. Refresh ICS baseline only after intentional green upgrades
5. Record compare runs after material harness changes (Phase 9)

## Agent contract
After research: propose concrete upgrades as `/learn` staging (upgrade-only). Do not auto-scrape or silent-overwrite. Run `Test-CI.ps1` before promote.
