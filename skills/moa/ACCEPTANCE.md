# /moa acceptance

**Legend:** `[CI]` = Test-Phase6/7 · `[human]` = live multi-model quality

- [x] `[CI]` `Invoke-MoA.ps1` writes plan under `memory/moa/`
- [x] `[CI]` Proposal pack truncates to max chars
- [x] `[CI]` Aggregator prompt includes proposals + query
- [x] `[CI]` Ledger entries skill=`moa`
- [x] `[CI]` `Test-Phase6.ps1` passes
- [x] `[CI]` `Test-SkillsGraph` includes moa
- [ ] `[human]` Aggregator answer quality vs single-model baseline
