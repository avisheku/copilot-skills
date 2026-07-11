---
name: create
description: Scaffold expert skill block; enforce abidance gate before promote.
---

# /create

Scaffold new versioned block under `skills/<id>/`.

## Scaffold (required files)

- SKILL.md (frontmatter)
- meta.json (`id`, `version`, `phase`)
- README.md · SETUP.md · ACCEPTANCE.md

## Abidance gate

Before promote, run:

```powershell
Import-Module .\scripts\modules\CopilotSkills.psm1 -Force
Invoke-CreateAbidanceGate -SkillPath .\skills\<id>
Test-SkillsGraph
```

Fails if pillars Y/B/C/M violated, missing files, or graph broken.

## delegatesTo

`research` for arch decisions when needed.

## Rules

- Config over hardcode
- Upgrade-only; no degrade
- Add entry to `config/skills.graph.json`
