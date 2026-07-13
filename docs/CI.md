# SkillsForge — CI and merge control

```text
InstallSmoke → Phase2 → GoldenPath → Phase4 → … → Phase11 → SecretsAudit
→ Export-LocalDashboard
```

Local: `.\scripts\Test-CI.ps1`

Job: **PowerShell gates**

| Layer | What | Merge block? |
|-------|------|----------------|
| L1–L5 | Structure through compare smoke | Yes |
| `/upgrade` scan | Phase10 inventory (no live scrape) | Yes (scan health) |
| Living matrix | Phase11 evidence/recommend/promote smoke | Yes |
