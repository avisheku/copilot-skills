# New Project Instructions

| Field | Value |
|-------|-------|
| **Purpose** | Generic constitution + create rules for **any** new project |
| **Use when** | Starting a project in Cursor / Claude / Copilot |
| **Canonical** | `KnowledgeVault/_templates/NEW_PROJECT_INSTRUCTIONS.md` |
| **Mirror** | `KnowledgeVault/projects/copilot-skills/docs/NEW_PROJECT_INSTRUCTIONS.md` |
| **Related** | `PILLARS.md` · `PRINCIPLES.md` · copilot-skills ADR (constitution detail) |
| **Vault** | `$M` = KnowledgeVault root |
| **Version** | 1.1 · 2026-07-12 |

**Agent contract:** Read this **before** scaffolding. Do not invent a different constitution. Ask only for project-specific deltas (name, domain, constraints). Keep domain rules inside that project’s `config/` and handbook — never bake them into this file.

---

## 0. How to use (you → agent)

> Create a new project using `NEW_PROJECT_INSTRUCTIONS.md`. Project name: `<NAME>`. Domain notes: `<optional>`. Abide all pillars; AI does setup; I do minimum manual only.

Agent then:

1. Confirm name + home path (default below).  
2. Short plan / dual-gate if non-trivial.  
3. `move_agent_to_root` into the project **before** edits.  
4. Scaffold per §4 + abidance gate.  
5. Stop at golden path unless you say continue.

---

## 1. Default home & workspace

| Rule | Detail |
|------|--------|
| **Preferred location** | `$M/projects/<kebab-name>/` |
| **Alt** | Only if you name another path explicitly |
| **Git** | `git init` on create unless you say otherwise |
| **Workspace** | `move_agent_to_root` on the project path **before** substantive work |
| **Vault hygiene** | Product code under `projects/` — not in `raw/`, `wiki/`, or `memory/` |
| **Deliverables** | Optional copies of plans/ADRs may go to `$M/outputs/` |

---

## 2. Seven pillars (must abide)

| # | Pillar | One-liner | Decision test |
|---|--------|-----------|---------------|
| **1** | One standard, many harnesses | Official patterns (`SKILL.md`, Compose, config); adapters = paths/config only | Body-transform per agent? → **No** |
| **2** | Code over vibes | Deterministic scripts/config/engines; AI for judgment / glue only | Logic only in prose? → **Codify** |
| **3** | Context thrift | Blank default; inject on need; no always-on dumps | Always-on full memory/rules? → **Reject** |
| **4** | Ask → confirm → finish | Clarify → research → short plan confirm → implement | Build before confirm? → **No** |
| **5** | Parallel safe, sequential sacred | Parallel independent work; sequential for gates / secrets / promote | Safety path parallel? → **No** |
| **6** | Measure → learn → promote | Ledger + tests; **upgrade-only**; root-cause; dual sync | Degrade / no evidence? → **Refuse** |
| **7** | Secrets stay local | Secrets, env, and personal data gitignored | Leak? → **Block** |

**Conflict order (locked):**  
correctness > thrift · safety > speed · evidence > hype · lean > completeness · shared > forks · **config > hardcode** · **native > custom** · replaceable > monolith · upgrade > silent overwrite.

---

## 3. Principles (Y–R)

| ID | Principle | Meaning |
|----|-----------|---------|
| **Y** | Essential-only | Need? → reuse? → native/stdlib? → dep? → minimum that works. Cite upstream; do not vendor without reason. |
| **B** | Composable blocks | Versioned modules + **config over hardcode**; add/kill/upgrade without rewrite. |
| **C** | Caveman accurate | Terse agent prose; **correctness > terseness**; paths, errors, and exact values stay exact. |
| **M** | Minimal surface | Only required files/comments/deps; no drive-by refactors. |
| **L** | Ship lean | MUST → SHOULD → DEFER → REJECT; **stop after golden path**. |
| **S** | Slash / skills over repetition | Prefer reusable skills/commands over re-pasting long prompts. |
| **P** | Professional packaging | README / SETUP / HANDBOOK VERIFY; shareable; PR-ready. |
| **G** | Compound growth | Learn → handbook/config upgrade; fixes compound across projects. |
| **R** | Root cause first | Reproduce → classify → fix or document; do not paper over. |

---

## 4. Packaging defaults (every new project)

### 4.1 Prefer this tree

```text
<project>/
  README.md                 # first line → docs/HANDBOOK.md
  docs/
    HANDBOOK.md             # AI + human install; VERIFY; troubleshoot
    constitution.md         # optional pointer to pillars
    principles.md           # optional pointer to Y–R
  config/                   # versioned YAML/JSON — tunables, not hardcoded logic
  scripts/                  # deterministic automation
  src/ or app/              # product code (as needed)
  data/                     # gitignored local inputs / runtime state
  ledger/                   # optional JSONL observability
  samples/                  # redacted examples only
  docker-compose.yml        # when a runtime exists
  Dockerfile                # when containerizing
  .env.example              # no secrets
  .gitignore                # data/, .env, secrets, personal files
  AGENTS.md                 # optional thin contract → HANDBOOK
```

### 4.2 Container / share

- **Containerize as much as practical** so others run:  
  `git clone` → `cp .env.example .env` → `docker compose up`
- Pieces that cannot be containerized (IDE skills, browser login, host encryption) = **host-optional**; do not block golden path.
- **Share code + Compose**, never personal `data/` or secrets.
- Prefer git over one-off zip shares.

### 4.3 Configurable / updatable

- Tunables live in `config/` (versioned files, feature flags, environment profiles).
- External rule/API/model changes = **new config + handbook note**, not silent hardcode.
- Mark unfinished work **DEFER**; do not fake completeness.

### 4.4 Living HANDBOOK

Single guide of record: `docs/HANDBOOK.md`.

| Mode | Audience |
|------|----------|
| AI | Numbered steps · exact commands · VERIFY · fail→goto |
| Human | Same steps + short why |
| Learn | Upgrade-only patches; never remove a working VERIFY without replacement |

```text
VERIFY:
  command: <exact>
  expect: <exit 0 / string>
ON_FAIL:
  goto: Troubleshoot#<id>
```

### 4.5 Abidance gate (fail create if missing)

- [ ] Pillars + Y/B/C/M applied  
- [ ] Config not hardcode; clear versions/ids where relevant  
- [ ] No secrets / personal files in git  
- [ ] README → HANDBOOK; share/run path documented  
- [ ] Golden path defined; DEFER list explicit  
- [ ] `.gitignore` covers `data/`, `.env`, and sensitive patterns  

---

## 5. AI vs you (default work split)

| Who | Does |
|-----|------|
| **AI / agent** | Scaffold, containers, deps, config, docs, skill wiring, research, automation, dry-runs, share pack |
| **You (minimum)** | Approve plan · place private inputs in `data/` · auth / OTP / irreversible confirmations · final human gate |

Do not ask the user to manually install stacks the agent can install. Prefer one-command setup.

---

## 6. Research & build preferences

| Preference | Rule |
|------------|------|
| **Free / OSS first** | Prefer open source, self-host, and existing tools; extend before reinventing |
| **Paid tools** | Use only when needed; prefer low cost; keep the local stack as the durable core |
| **Trusted sources** | Prefer official docs, audited OSS, and registered/compliant providers for sensitive domains |
| **Hybrid OK** | Local stack = brain; external SaaS = optional edge when complexity warrants |
| **Native > custom** | Official APIs, Compose, standard skill formats, stdlib before bespoke frameworks |
| **Deterministic core** | Scripts/engines for critical outputs; LLM for extract/explain/glue only |
| **Human gate** | Never auto-submit credentials, OTP, payments, or irreversible actions for the user |
| **Host default** | Assume Windows + PowerShell unless told otherwise; document other OS if Compose supports them |

---

## 7. Dual gates (before implement)

1. **Clarify** — name, scope, constraints, non-goals  
2. **Research** — existing tools / vault priors / official docs  
3. **Confirm** — short plan (or plan-mode approval)  
4. **Implement** — essentials → VERIFY → stop and use  

Do not implement a new project during pure research unless the user says **execute**.

---

## 8. Phasing language

| Stage | Meaning |
|-------|---------|
| **MUST** | Golden path — without it the project is useless |
| **SHOULD** | Next block after golden path works |
| **DEFER** | Stub only; no fake features |
| **REJECT** | Out of scope / overbuild |

After golden path green → **STOP AND USE** unless the user requests the next phase.

---

## 9. Observability & learn

- Prefer append-only `ledger/*.jsonl` for runs/errors when automation exists.  
- Capture gotchas in project `docs/` or vault tooling notes — **do not repeat**.  
- Upgrades are **upgrade-only** (no silent degrade of working VERIFY/config).  

---

## 10. Secrets & personal data

- Never commit: `.env`, API keys, tokens, session cookies, or personal/private documents.  
- `data/` is local only (bind-mount / gitignored).  
- `samples/` must be **redacted**.  
- User types credentials at use time; do not store them in code.  

---

## 11. Copy-paste agent prompt

```text
Read and abide: KnowledgeVault/_templates/NEW_PROJECT_INSTRUCTIONS.md
(or projects/copilot-skills/docs/NEW_PROJECT_INSTRUCTIONS.md)
Create project: <NAME>
Home: KnowledgeVault/projects/<NAME>  (unless I override)
move_agent_to_root before edits.
Docker-shareable if it has a runtime; config over hardcode; essentials → golden path → STOP.
AI does setup; I only approve / drop private data / auth / final gate.
Prefer free OSS; paid only if needed.
Keep this instruction file generic — put domain rules in the new project's config/handbook.
Do not change unrelated plans/files.
```

---

## 12. Scope of this file

This file holds **cross-project** rules only: pillars, principles, packaging, gates, shareability, AI/human split.

**Out of scope here:** any single product’s domain logic, vendor picks, schemas, or feature lists. Those belong in that project’s `config/` and `docs/HANDBOOK.md`.

---

## 13. Quick checklist (print at create)

- [ ] Path = `$M/projects/<name>` (+ `move_agent_to_root`)  
- [ ] Pillars + Y/B/C/M/L/P applied  
- [ ] `docs/HANDBOOK.md` with VERIFY  
- [ ] `config/` for tunables  
- [ ] Docker Compose when a runtime exists  
- [ ] `.gitignore` locks secrets + `data/`  
- [ ] Golden path + DEFER list written  
- [ ] Share/run path documented  
- [ ] User manual steps kept minimal  

**End of instructions.**
