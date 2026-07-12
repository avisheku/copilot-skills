# Copilot Skills Pack

Windows-first skills harness for VS Code Copilot and Claude Code.

**Start here:** [docs/HANDBOOK.md](docs/HANDBOOK.md)

| Doc | Purpose |
|-----|---------|
| [HANDBOOK](docs/HANDBOOK.md) | Install, configure, troubleshoot |
| [CI](docs/CI.md) | GitHub Actions + merge protection |
| [ADR](docs/plan/ADR.md) | Solution architecture + decisions |
| [Implementation plan](docs/plan/IMPLEMENTATION_PLAN.md) | Phases 0–10 |
| [SETUP](SETUP.md) | Setup pointer |

## Phases

| Phase | Doc |
|-------|-----|
| 6 MoA | [PHASE6_MOA.md](docs/plan/PHASE6_MOA.md) |
| 7 Governance | [PHASE7_GOVERNANCE.md](docs/plan/PHASE7_GOVERNANCE.md) |
| 8 ICS quality | [PHASE8_QUALITY_GATE.md](docs/plan/PHASE8_QUALITY_GATE.md) |
| 9 Compare tracker | [PHASE9_COMPARE_TRACKER.md](docs/plan/PHASE9_COMPARE_TRACKER.md) |
| 10 Upgrade / frontier | [PHASE10_UPGRADE.md](docs/plan/PHASE10_UPGRADE.md) |

**CI:** InstallSmoke → Phase2 → GoldenPath → Phase4–10. **Defer:** [docs/DEFER.md](docs/DEFER.md).

**Stay current:** `.\scripts\Invoke-UpgradeScan.ps1` → `evidence\upgrade\report.md`  
**Prove effectiveness:** `.\scripts\Seed-CompareDemo.ps1` → `evidence\compare\report.html`
