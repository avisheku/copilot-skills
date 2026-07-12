# /learn acceptance

**Legend:** `[CI]` = enforced by Test-Phase4/7 or promote gate · `[human]` = chat/process judgment

- [ ] `[human]` Root cause documented before promote
- [x] `[CI]` Upgrade-only check passes (growth allowed; shrink rejected)
- [x] `[CI]` Handbook patches keep VERIFY / ON_FAIL blocks (`Test-HandbookVerifyIntact`)
- [ ] `[human]` Dual sync when promoting skills (`-DualSync` on promote)
- [x] `[CI]` L1+L2 promote gate runs before promote (`Invoke-L2PromoteGate`)
- [x] `[CI]` Quality gate (ICS) on md/handbook/moa promote targets (`Invoke-QualityGate`)
