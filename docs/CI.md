# CI and merge control

Simple GitHub Actions gate. Green checks required before merge.

## What runs

Workflow: `.github/workflows/ci.yml`

On every **push** and **pull request** to `master`/`main`:

```text
Test-Phase2 → Test-GoldenPath → Test-Phase4 → Test-Phase5 → Test-Phase6
```

Local:

```powershell
.\scripts\Test-CI.ps1
```

## Enable merge protection (one-time)

After the first green CI run on GitHub:

### UI (easiest)

1. https://github.com/avisheku/copilot-skills/settings/branches  
2. **Add rule** → Branch name pattern: `master`  
3. Check:
   - **Require a pull request before merging**
   - **Require status checks to pass before merging** → search **PowerShell gates**
   - **Require branches to be up to date before merging**
4. Save

### CLI

```powershell
.\scripts\Enable-BranchProtection.ps1
```

(Requires `gh` auth. Run CI once first so the check name exists.)

## How merges work

```text
feature branch → push → CI runs → open PR
                         ↓
              PowerShell gates green? → merge allowed
                         ↓ red
              fix → push again → CI re-runs → merge blocked until green
```

## Fail = reject

| Result | Action |
|--------|--------|
| CI green | Merge PR |
| CI red | Do not merge; fix and push |
| No check yet | Push once to create the check, then enable protection |
