# Copilot Skills Pack — Solution Architecture Plan (v2)

Document type: Solution design (presentable)
Status: **REV 2 — research-updated · pending user approval** (v1 was APPROVED 2026-07-11; v2 changes need one confirm)
Revision date: 2026-07-11
Primary platform: Windows · VS Code · GitHub Copilot
Repo: `C:\Users\avish\Documents\KnowledgeVault\projects\copilot-skills`
Vault: `C:\Users\avish\Documents\KnowledgeVault`
Owner build model: Agent implements · You approve path, run installer once, fill env/user.md
Supersedes: `copilot_skills_pack_ca98203f.plan.md` (v1, chat-only — never written to disk)

---

## 0. Approval record

### 0.1 v1 verdict (unchanged, preserved)

APPROVED WITH CONDITIONS — architecture sound; scope tightened ≤ ~20% plan change for ~80% delivery/value gain. Execute Phases 0–3 only until golden path passes; do not start Appendix B.

**v1 approver Pareto (P1–P7, still locked):**

| # | 20% change | Why ~80% gain | Action |
|---|---|---|---|
| P1 | Core skill cut: full build = /do /research /magic /sync /mcp /create only | Less surface → faster MVP | Phase 2 MUST = 6 skills; learn/stats/audit = stubs until Phase 4 |
| P2 | One golden-path acceptance (install → /mcp → /do tiny goal → /magic → handoff) | Defines "done" | Phase 3 MUST exit criterion |
| P3 | Always-on token budget gate (~≤1.5k) | Stops context rot at source | Phase 1 L1 check — v2: measure skill **descriptions** (see N5) |
| P4 | Single shared gate/ShortPlan module for /do + /research | One fix improves both | Phase 2 MUST |
| P5 | Research depth default = 1 | Cuts Phase 3 complexity | Phase 3 MUST; deeper nest → DEFER |
| P6 | Install smoke in Phase 1 before writing all skills | Fail fast on paths/sync | Phase 1 MUST |
| P7 | One delegatesTo: research fixture in Phase 3 | Proves pillar 10 cheap | Phase 3 MUST |

**v1 conditions (still hold):** Copilot-first · no global-instructions dump · no DEFER pull without measured pain · /magic stays user Pareto design · /learn sources-map on explicit ask only · stop after Phase 3 golden path.

### 0.2 v2 revision record — research delta (2026-07-11)

Independent research (VS Code docs, GitHub changelog, agentskills.io ecosystem) found the mid-2026 harness made several v1 custom builds **native**. v1 was written against an older Copilot model. Facts:

| # | Fact (verified 2026-07) | Source |
|---|---|---|
| F1 | **Agent Skills = open standard**, native in VS Code/Copilot, Copilot CLI, Copilot cloud agent, Cursor, Claude, Codex, ~40 tools. Same SKILL.md works unmodified everywhere. | code.visualstudio.com/docs/agent-customization/agent-skills · agentskills.io |
| F2 | VS Code reads skills from `.github/skills/`, `.claude/skills/`, `.agents/skills/` (workspace) and `~/.copilot/skills/`, `~/.claude/skills/`, `~/.agents/skills/` (user). Extra paths via `chat.agentSkillsLocations`. | VS Code agent-skills doc |
| F3 | Native frontmatter: `user-invocable`, `disable-model-invocation`, `argument-hint`, `context: fork` (skill runs in own subagent context — experimental, `github.copilot.chat.skillTool.enabled`). 3-level progressive disclosure built in (name+desc always → body on invoke → resources on demand). | VS Code agent-skills doc |
| F4 | **Agent hooks (Preview)**: PreToolUse / PostToolUse / SessionStart etc., JSON stdin→stdout, `permissionDecision: allow\|ask\|deny`, PostToolUse can `decision: block`. **Same format as Claude Code and Copilot CLI.** Agent-scoped hooks in `.agent.md` frontmatter. | code.visualstudio.com/docs/agent-customization/hooks |
| F5 | **Agent plugins (Preview)**: `plugin.json` bundles skills + agents + hooks + `.mcp.json` MCP servers. Install via git URL, local path (`chat.pluginLocations`), or marketplace (`awesome-copilot`, `copilot-plugins` default). **Claude-plugin format auto-detected** (`.claude-plugin/`). Copilot CLI plugins auto-appear in VS Code. Org gate: `chat.plugins.enabled`. | code.visualstudio.com/docs/agent-customization/agent-plugins |
| F6 | **Native subagents run in parallel**, own context windows, configurable concurrency + depth limits; `chat.agent.maxRequests` caps loop; Agent Sessions view for local/background/cloud. Custom agents = `.github/agents/*.agent.md`. | VS Code multi-agent blog 2026-02 · changelog |
| F7 | Harness auto-**summarizes/compacts** conversation when context grows; tools exposed dynamically per request; per-model routing internal. | VS Code harness blog 2026-05-15 |

### 0.3 v2 Pareto — new ≤20% changes → ~80% gain (N1–N7)

| # | 20% change | Why ~80% gain | Fate of v1 item |
|---|---|---|---|
| N1 | **Author in Agent Skills standard, not custom blocks.** SKILL.md is the source; deploy = copy/junction into `~/.copilot/skills` + `~/.claude/skills` (or one `~/.agents/skills`). No body transforms ever. | Kills the entire adapter/transform layer; Cursor + Claude go from "stubs" to **near-free tier-1** — same folders, zero rework | v1 block-transform adapters → DEFER (config-only adapters stay) |
| N2 | **Hooks = the real deterministic control plane.** Guardrails (secret-leak block, gate-skip block, danger commands), ledger (PostToolUse → JSONL), session budget warn — as hooks shared verbatim across Copilot + Claude + CLI (F4: same format). | Pillar 2 was claimed but guardrails were prompt-text = vibes. Hooks give **guaranteed** enforcement + free observability | PS modules become hook payloads + installer, not runtime engine |
| N3 | **Native subagents replace custom parallel engine.** /do plans with `context: fork` skills / `.agent.md` custom agents; concurrency + depth = harness settings; `chat.agent.maxRequests` caps runaway. | Deletes the hardest, most fragile MVP build (PS DAG/wave dispatcher) — harness already does it, tested at Microsoft scale | v1 wave dispatcher → DEFER (only if native limits measurably hurt) |
| N4 | **Repo IS the plugin.** `plugin.json` at root + `.claude-plugin/` compat manifest → install = one git/path command on Copilot, CLI, and Claude Code; auto-sync between them. | Layer A packaging becomes ~1 file instead of a build step; office install = local-path, no marketplace | VSIX stays DEFER; Layer B (plain skill folders) kept as fallback when org blocks plugins |
| N5 | **Invocation policy via native frontmatter.** `disable-model-invocation: true` on heavy skills (explicit `/` only), `user-invocable: false` on delegation-only sub-skills. Budget gate P3 now measures sum of `description` fields (the actual always-on cost). | Encodes pillar 3 + anti-auto-invoke REJECT in metadata the harness enforces, not prose the model may ignore | P3 gate kept, retargeted |
| N6 | **Upgrade lane: COMPAT.md + VERSIONS.md + `/sync -Check` drift detection.** COMPAT.md pins every Preview feature assumption (hooks, plugins, fork-context) with a tested fallback; `/sync -Check` diffs installed vs repo and flags harness feature drift. | User's stated goal = "easily update and upgrade, base solid." Preview features WILL churn; this makes churn a 10-min patch, not a rebuild | New MUST, Phase 0/1 |
| N7 | **Golden path gains hook evidence.** Acceptance adds: ledger JSONL exists + contains the /do run's tool calls (proves control plane live, not just prompts). | Verifies the one thing v1 couldn't: runtime enforcement actually ran | P2 extended, not replaced |

**v2 conditions (add to v1's):**
- Hooks/plugins/fork-context are **Preview** → every use must have a COMPAT.md fallback (prompt-level guardrail + plain skill folders). Never hard-depend on Preview behavior for correctness of *user data* — only for enforcement/telemetry.
- Nothing from v1 is deleted — displaced items moved to Appendix B with reason tags.

---

## 1. Executive summary

Build a global slash-command / skills pack that makes Copilot (and, via the shared standard, Claude/Cursor) work like a deterministic harness: thin AI prompts in **standard SKILL.md**, **hooks** as the deterministic control plane, PowerShell for install/config only, inject-only context, dual gates before work, **native parallel subagents**, and a learn loop that improves the pack with evidence.

| | |
|---|---|
| Problem | Agent chats waste tokens, redo workflows, dump always-on instructions, lack repeatable office-safe install |
| Solution | Standard skills + plugin manifest + shared hooks; /do + /research orchestration; context/rules/memory switch on need; caveman-lean prompts; /learn with evidence |
| MVP | Phases 0–3 on Copilot · 6 full skills · golden path (with hook evidence) → stop and use |
| Status | v1 APPROVED · v2 revision pending one confirm |
| Later | Phase 4 SHOULD; Phase 5+ DEFER (Appendix B) |
| Non-goals | Not vendoring community runtimes; no Copilot global instruction dumps; no custom engines duplicating native harness features |

```
User /slash → Standard SKILL.md (6 core) → Hooks control plane (guard·ledger·budget)
            → Context/rules/memory inject → Gates → confirm → native parallel subagents
            → Restore blank defaults → Ledger JSONL → /learn staging
```

---

## 2. Goals and non-goals

### Goals (MVP)
1. Install once → global `/` commands on Copilot (plugin + user skills); same folders serve Claude/Cursor.
2. Context lean: blank default; inject per task/skill; restore after; heavy skills explicit-invoke only (N5).
3. /do and /research: ask → research → ask → ShortPlan confirm → finish.
4. Parallel via native subagents; sequential for safety (gates, confirm, promote).
5. **Runtime enforcement via hooks**: secrets block, ledger, danger stop (N2).
6. Secrets and customer rules local (gitignored); team gets non-secret share.
7. Measure sessions (hook ledger); stage improvements; never silent overwrite.
8. **Upgradeable base**: COMPAT.md fallbacks + versioned drift checks (N6).

### Non-goals (REJECT — unchanged from v1, plus one)
- SaaS observability default · always-on full MCP/memory/rules · global-instructions dumps · vendoring community runtimes · fake savings claims · parallel before confirm · copy-pasting skill bodies · auto-invoke-everything
- **NEW: building custom runtime engines for anything the harness ships natively** (parallelism, compaction, progressive disclosure). Custom code = install/config/hooks only.

---

## 3. Locked decisions (facts — v2 updates marked)

| Decision | Value |
|---|---|
| Repo path | `KnowledgeVault\projects\copilot-skills` |
| OS / IDE | Windows + VS Code Copilot first |
| **Skill format** | **Agent Skills open standard (SKILL.md + frontmatter)** — v2 change, was custom blocks |
| Packaging | **Repo-as-plugin: `plugin.json` + `.claude-plugin/` compat** (Layer A) + plain user skill folders (Layer B fallback); VSIX = DEFER |
| Targets | Copilot full · **Claude/Cursor: same skill folders + per-target config (MCP, settings)** — v2 upgrade from "stubs" |
| **Control plane** | **Hooks (PreToolUse/PostToolUse/SessionStart) shared Copilot+Claude+CLI; PowerShell = installer/config/hook payloads only** — v2 change |
| **Parallelism** | **Native subagents + `context: fork`; concurrency/depth via harness settings** — v2 change, was custom waves |
| Inspiration | Cite in docs/SOURCES.md; do not vendor |
| /magic | User's Pareto design (≤~20% / ~80%) |
| Session default | Inherit user's model/MCP; only /do may snapshot→switch→restore |
| Wire format | Compact JSON; TOON = DEFER |
| /loop | DEFER |

---

## 4. Architecture pillars (v2 amendments in bold)

| # | Pillar | One-liner (v2) | Decision test |
|---|---|---|---|
| 1 | One **standard**, many harnesses | **Author Agent Skills standard once; harnesses read same folders; adapters = config only, never skill bodies** | Transform a skill body per agent? → No |
| 2 | Code over vibes | **Enforcement via hooks (deterministic, guaranteed); prompts guide, hooks guarantee**; config over hardcode | Guardrail as prompt text only? → add hook or COMPAT fallback |
| 3 | Context thrift | Inject on need; lean + caveman; **`disable-model-invocation` on heavy skills; budget = sum of descriptions** | Always-on rules/memory? → Reject |
| 4 | Ask → confirm → finish | Dual gates + ShortPlan for /do and /research | Fan-out before confirm? → No |
| 5 | Parallel safe, sequential sacred | **Native subagent concurrency/depth; harness caps (`chat.agent.maxRequests`)**; sequential for gates/confirm/promote | Safety-critical? → Sequential |
| 6 | Measure → learn → promote | **Ledger from PostToolUse hook (JSONL)**; /learn global fix on explicit ask | No evidence? → staging only |
| 7 | Compound growth | Field-expert /create; playbooks; global fixes help everyone | Next skill smarter? → Inherit |
| 8 | Secrets stay local | secrets/ + env/user + rules/user gitignored; **PreToolUse hook blocks secret paths** | Leak to git/chat? → Block (enforced) |
| 9 | Ship lean | MUST → SHOULD → DEFER → REJECT; **never rebuild what harness ships** | MVP done? → DEFER rest |
| 10 | Slash over repetition | Use `/` + delegation (**`context: fork`, `user-invocable: false` sub-skills**) | About to repeat? → Call slash |

Conflict resolution (unchanged): correctness > thrift · safety > throughput · evidence > clever · lean > completeness · shared core > per-harness hacks · config > hardcode · slash > repetition · evidence > hype. **v2 add: native > custom (harness feature beats own engine unless measured pain).**

---

## 5. Scope triage (v2)

### MUST — Phases 0–3 (MVP)
1. Repo + pillars + SOURCES + gitignore + **AGENTS.md + COMPAT.md + VERSIONS.md** (N6)
2. Install / uninstall / sync (Copilot plugin + user folders; **same skill folders registered for Claude/Cursor**) + Phase 1 smoke + **`/sync -Check` drift detection**
3. **hooks.json control plane: secret-path block · danger-command deny · ledger JSONL · session-start context stamp** (N2) — with COMPAT fallback documented
4. MCP profiles + explicit /mcp
5. Context packs + memory switch + rules switch + restore
6. Caveman + lean prompts + **descriptions-sum budget gate ≤ ~1.5k tokens** (P3/N5)
7. Full skills (standard SKILL.md): **/do /research /magic /sync /mcp /create** (P1)
8. Thin stubs: /learn /stats /audit (Phase 4)
9. Dual gates + ShortPlan via one shared module (P4); research depth 1 (P5)
10. **Native-subagent dispatch in /do** (`context: fork` / .agent.md), delegation fixture (P7), ledger + handoff pack
11. Session inheritance; secrets/rules isolation
12. Pester L1 + minimal L2 + **golden path incl. hook-ledger evidence** (P2/N7)

### SHOULD — Phase 4 (after MVP use)
- Full /learn kinds (setup/sync/arch/playbook + sources-map on explicit ask)
- **/stats reads hook ledger JSONL** (near-free now) + lean /audit -Summary
- Playbooks → /create inherit; expert bar enforcement
- Promote gates L1+L2; audit baseline
- Memory-build (team/skill notes, switch-on-demand)
- Agent-scoped hooks on /do's custom agent (.agent.md frontmatter)

### DEFER — Phase 5+ (Appendix B; v1 items preserved + v2 displacements added)
- **v2-displaced:** custom block registry/transform adapters · custom parallel wave/DAG dispatcher · custom token-threshold handoff automation (harness compacts natively; handoff pack stays manual-triggerable) · per-target skill-body forks
- **v1 list unchanged:** TOON · /loop · VSIX · Firm pack · OTel · Graphify/Neo4j · magic lenses · Superpowers auto-invoke · full model-matrix · sources auto-scrape · month-plan precision · deeper research nesting

### REJECT — never (see §2)

---

## 6. Solution design (v2)

### 6.1 Packaging (pillar 1 — simplified by F1/F2/F5)

```
copilot-skills repo
├─ plugin.json            # Copilot plugin manifest (skills/agents/hooks/.mcp.json paths)
├─ .claude-plugin/        # Claude Code plugin compat manifest
├─ skills/<id>/SKILL.md   # ONE source, standard format — no transforms
├─ agents/do.agent.md     # /do orchestrator custom agent (agent-scoped hooks Phase 4)
├─ hooks/hooks.json + payloads (PS)
└─ .mcp.json              # plugin-scoped MCP servers
```

Install paths:
- **Layer A (preferred):** plugin via local path (`chat.pluginLocations`) or git — works in VS Code, Copilot CLI, Claude Code from the same repo.
- **Layer B (fallback, office-safe):** installer copies/junctions `skills/` → `~/.copilot/skills/` + `~/.claude/skills/` (+ Cursor path) and merges hooks into per-target settings. Used when `chat.plugins.enabled` is org-blocked.

`Install-CopilotSkills.ps1 -Target Copilot|Claude|Cursor|All -Layer Auto|Plugin|Folders`

### 6.2 Skill shape (standard, replaces custom block.json)

```
skills/<id>/
  SKILL.md          # frontmatter: name, description, argument-hint,
                    #   user-invocable, disable-model-invocation, context: fork (where apt)
  ACCEPTANCE.md · README.md · artifacts/ · scripts/ · caveman.md (opt) · rules/ (opt)
```
Delegation metadata (delegatesTo / memoryRefs / ruleRefs / secretRefs names) → small `meta.json` sidecar per skill + generated `config/skills.graph.json` (replaces v1 blocks.registry.json). Shared: `shared/{instructions,artifacts,modules,templates,schemas}`.

Frontmatter policy (N5):
| Skill | user-invocable | disable-model-invocation | context |
|---|---|---|---|
| /do /research /magic /sync /mcp /create | true | true (explicit `/` only) | do: default; research: fork |
| delegation sub-skills | false | false | fork |
| stubs | true | true | default |

### 6.3 Core slash commands (unchanged roles; /do internals now native-subagent)

| Command | MVP role | Depth |
|---|---|---|
| /do | Gate1 → research → Gate2 → ShortPlan confirm → **native parallel subagents** → until-goal → /magic | Full |
| /research | Same gates+confirm; fan-out via fork subagents + synth (depth 1) | Full |
| /magic | Pareto ≤20%/≤80%; slash candidates | Full (user design) |
| /sync | Repo ↔ installed sync + `-Check` drift | Full |
| /mcp | Explicit profile switch / restore | Full |
| /create | Field-expert scaffold (emits standard SKILL.md + meta.json) | Full |
| /learn /stats /audit | Stubs → Phase 4 | Stub |
| /loop | — | DEFER |

### 6.4 /do //research flow (pillar 4 — unchanged logic, new dispatch)
Gate1 → research (local-first; catalog sources; fan-out after confirm) → Gate2 → ShortPlan+FullPlan confirm → **dispatch: fork-context skills / custom agents; concurrency + depth via harness settings (target ≤3); `chat.agent.maxRequests` as hard cap** → verify → remediate/advance → /magic → optional /learn staging. Workers get sliced FullPlan + caveman-full brief (compact JSON). Long sessions: harness auto-compacts (F7); handoff pack generated on demand or at Gate boundaries, not via custom token counters.

### 6.5 Context thrift (pillar 3 — unchanged, plus native levers)
Blank defaults; packs/memory/rules inject-restore per task. Native levers now do part of the work: 3-level disclosure (F3), `disable-model-invocation`, fork contexts don't pollute main window (F6). Rules merge order: global → skill → firm → user (last wins), cap via rules-policy.json. REJECT global copilot-instructions dumps — unchanged.

### 6.6 Hooks control plane (NEW — pillar 2/6/8 enforcement)

| Hook | Event | Action |
|---|---|---|
| guard-secrets | PreToolUse | deny file/terminal ops touching `secrets/**`, `env/user*`, `rules/user/**` |
| guard-danger | PreToolUse | deny/ask on destructive command patterns (config/guardrails.json) |
| ledger | PostToolUse | append JSONL: ts, session, tool, target, outcome → `logs/ledger/` |
| session-stamp | SessionStart | inject active pack/profile names (≤~100 tokens) |

Same hooks.json consumed by VS Code, Copilot CLI, Claude Code (F4). COMPAT fallback: if hooks unavailable → prompt-level guardrails + /audit manual ledger note; budget gate still enforced at L1 test time.

### 6.7 Lean prompts + caveman (unchanged)
ShortPlan lite · worker briefs full · code/paths/errors exact · always-on = name+description only.

### 6.8 Secrets and sharing (unchanged tiers; now hook-enforced)
Team (commit) / Firm (private remote) / User (gitignore). /learn cannot promote into user tiers without explicit ask. PreToolUse hook = second lock.

### 6.9 /learn (unchanged design; ledger makes evidence cheaper)
MVP staging stub. Phase 4 kinds incl. sources-map on explicit ask only.

### 6.10 Delegation + parallelism (merged; native)
FullPlan tasks: skillId + delegatesTo → parent invokes `/skill` (fork context) or custom agent; depth ≤2 via harness depth limit; parent pack restore after. Sequential sacred list unchanged: gates, confirm, verify-deps, restore, promote.

---

## 7. Target repository layout (v2)

```
copilot-skills/
  README.md · AGENTS.md · ARCHITECTURE.md · ACCEPTANCE.md
  plugin.json
  .claude-plugin/plugin.json
  docs/    PILLARS.md · SOURCES.md · REFERENCES.md · COMPAT.md · VERSIONS.md
  config/  pillars.json · targets.json · skills.graph.json · session-policy.json
           rules-policy.json · learn.json · guardrails.json
           caveman/{global.md,levels.json} · context-packs/ 
           mcp/{profiles/,servers.catalog.json} · research/sources.json
  skills/  {do,research,magic,sync,mcp,create,learn,stats,audit}/SKILL.md …
  agents/  do.agent.md
  hooks/   hooks.json · payloads/*.ps1
  .mcp.json
  rules/   global/ skill/ user/ firm/
  shared/  instructions/ artifacts/ modules/ templates/ schemas/
  env/  memory/  secrets/  learn/  tests/  scripts/  logs/
```

---

## 8. Delivery roadmap (v2 — [A] agent · [U] you)

### Phase 0 — Bootstrap · MUST
- [A] Repo at KnowledgeVault path + git init; move agent workspace root
- [A] Scaffold v2 layout + .gitignore (secrets, env/user, memory/user, rules/user, logs/ledger raw)
- [A] docs: PILLARS (v2 text) · ARCHITECTURE · ACCEPTANCE · SOURCES · REFERENCES · **COMPAT.md (Preview-feature matrix + fallbacks) · VERSIONS.md** · AGENTS.md
- [A] plugin.json + .claude-plugin manifest skeletons; config stubs incl. skills.graph.json
- [U] Confirm VS Code current + Copilot Chat; confirm whether org allows `chat.plugins.enabled` (decides Layer A vs B default)

### Phase 1 — Control plane · MUST
- [A] PS modules: Paths, Config, Install, Sync (+`-Check` drift), McpProfile, ContextPack (Memory+Rules), Caveman, HookPayloads
- [A] Install-/Uninstall-/Sync-*.ps1 with -Target (Copilot full; **Claude/Cursor = folder-registration, not stubs**) and -Layer Auto|Plugin|Folders
- [A] **hooks/hooks.json + payloads: guard-secrets, guard-danger, ledger, session-stamp**; verify fire on Copilot; note Claude parity in COMPAT
- [A] MCP catalog + profiles (minimal + 1–2) + Set-McpProfile.ps1
- [A] Context pack + memory + rules inject/restore; rules-policy.json; caveman global+levels
- [A] **Budget gate L1: sum of all skill `description` fields + session-stamp ≤ ~1.5k tokens**
- [A] Env/secret templates; sync refuses private paths
- [A] Pester L1: paths, sync dry-run, drift-check, profile, inject/restore, caveman merge, rules switch, budget gate, **hook payloads unit-tested (JSON in→out)**
- [A] Install smoke: dry-run install + list skills in `/` menu + one hook fires (fail fast)
- [U] Copy env/user.example.md → env/user.md

### Phase 2 — Skills + dual deploy · MUST
- [A] 6 full skills as standard SKILL.md (frontmatter per §6.2 policy) + meta.json sidecars → generated skills.graph.json
- [A] One shared Gate1/Gate2/ShortPlan module (P4)
- [A] 3 stub skills (one-screen, "Phase 4")
- [A] Research sources merge helper; depth default 1 in config
- [A] Deploy Layer A (plugin) + Layer B (folders) on Copilot; **register same folders for Claude Code; Cursor per COMPAT**
- [A] Schema validators + light ACCEPTANCE per full skill
- [U] Run installer; verify `/sync`, `/mcp`, and skills visible in **both** Copilot and Claude Code

### Phase 3 — /do brain · MUST → **MVP STOP**
- [A] session-policy.json (target concurrency 3, depth 2 → harness settings where exposed)
- [A] /do: Gate1 → delegate research (fork) → Gate2 → confirm → until-goal → /magic; snapshot MCP+model → apply post-confirm → restore
- [A] Standalone /research: dual-gate + confirm → fork fan-out + synth (depth 1)
- [A] FullPlan schema: skillId, dependsOn, parallelGroup (maps to fork dispatch order); compact JSON briefs
- [A] Handoff pack generator (on-demand + Gate boundaries)
- [A] Non-/do never calls Set-McpProfile
- [A] Fixtures: dual gates, confirm, restore, delegation fixture (P7), stub-learn no-MCP-flip
- [A] **Golden path ACCEPTANCE: install → /mcp minimal → /do tiny goal → /magic → handoff file exists → ledger JSONL contains the run** (P2+N7)
- [U] Optional model IDs/thresholds once; then **use the pack for real work**

### Phase 4 — Learn & audit maturity · SHOULD
Promote learn/stats/audit; full /learn kinds; **/stats over hook ledger**; playbooks → /create bar; promote gates L1+L2; audit baseline; agent-scoped hooks on do.agent.md; example domain skill with delegatesTo; research depth >1 if pain measured.
- [U] Run /audit then /learn after a messy real session

### Phase 5+ — DEFER only (Appendix B). Pull only on measured pain + explicit ask.

---

## 9. Success criteria (MVP done when golden path passes and:)
- Pillars 1–6, 8–9 live on Copilot; pillar 7 stub/staging
- 6 full skills + 3 stubs; **same skill folders visible in Claude Code** (Cursor noted in COMPAT)
- **Hook control plane live: ledger JSONL + secret-block verified** — or documented COMPAT fallback active
- Descriptions budget gate green; rules/memory inject-on-need
- Default commands inherit model/MCP; only /do orchestrates then restores
- /do + /research ask→confirm→finish; depth-1 research; native parallel dispatch
- Delegation fixture green; secrets/rules/user local
- COMPAT.md + VERSIONS.md current; `/sync -Check` clean
- No DEFER item required

---

## 10. Risks and mitigations (v2)

| Risk | Mitigation |
|---|---|
| **Preview churn (hooks/plugins/fork)** | COMPAT.md pins assumptions + fallback per feature; `/sync -Check` flags drift; Layer B always works |
| **Org policy blocks plugins** | Layer B folder install is first-class, not afterthought |
| Context bloat | Blank default; switches; caveman; native disclosure + fork contexts; descriptions budget |
| Runaway agents | Dual gates + confirm; harness concurrency/depth caps + `chat.agent.maxRequests`; guard-danger hook |
| Secret leak | Gitignore + promote blocks + **PreToolUse hook** + redacted audit |
| Overbuilding | Pillar 9 + "native > custom" rule; MVP stop after Phase 3 |
| Stale inspiration | /learn -Sources on ask; monthly skim (manual) |

---

## Appendix A — Inspiration source map (unchanged from v1; ship in Phase 0)
Standards: agentskills.io · anthropics/skills · MCP registry/SDKs · VS Code agent-customization docs (skills/hooks/plugins/agents). Catalogs: obra/superpowers · github/awesome-copilot · awesome-agent-skills · addyosmani/agent-skills · harness-flow · compound-engineering. MCP: punkpeye/awesome-mcp-servers · modelcontextprotocol/servers. Harness: awesome-harness-engineering · karpathy autoresearch/nanochat · skill-router · Conductor · Aider repo-map · OpenHands. Frontier: Anthropic/OpenAI/GitHub/VS Code/Cursor blogs · arXiv · changelogs. Policy: inspire, never vendor. Update via /learn -Sources on ask.

## Appendix B — Full DEFER backlog (v1 preserved + v2 displacements)

**B0. v2-displaced (was MUST machinery in v1 — superseded by native features; revive only on measured pain):**
- Custom block registry + per-target body transform adapters (native standard covers)
- Custom parallel wave/DAG dispatcher + multi-process worker pool (native subagents cover)
- Custom token-threshold counters for auto-handoff (harness compaction covers; manual handoff pack stays)
- Per-target skill-body forks of any kind

**B1. Runtime & packaging:** /loop STATE machine · TOON + encoder · VSIX Layer C · Cursor/Claude hardening beyond folder parity · Firm pack + threat model + supply-chain freeze · custom agents fork matrix / capability ladder
**B2. Research & graph:** Graphify/Aider repo-map lane · Neo4j/LangGraph/GraphRAG · Obsidian deep integration
**B3. Magic & lenses:** lenses.json · apply-one + CONCERNS · two-stage review · research depth >1
**B4. Harness prior-art:** skill-router meta-skill · evidence router · lifecycle map · Iron Laws tables · harness-planes audit checklist · negative examples · sibling rollup · supply-chain scan
**B5. Famous packs (patterns only; REJECT auto-invoke-all):** karpathy keep/discard + nanochat dial · karpathy-lite rules · GStack role pack · Aider map-tokens · OpenHands triggers
**B6. Token/context extras:** docs/CONTEXT.md · ignore templates · tool-offload helper · thinking-budget column · freezeCustomizationsIndex notes · effective-window soft threshold · user-memory cap · Copilot Memory (Firm)
**B7. Observability & planning:** OTel bridge · Promptfoo L3 · New-MonthPlan pricing · maturity.json automation · Refresh-Sources auto-digest
**B8. Misc:** domain pack stub · office install guide · Memo MCP · quarterly awesome-harness skim

## Appendix C — Key references (v2 refresh)

| Source | Use |
|---|---|
| VS Code — Agent Skills docs | Standard format, paths, frontmatter, disclosure (F1–F3) |
| VS Code — Agent hooks (Preview) | Control plane format, events, decisions (F4) |
| VS Code — Agent plugins (Preview) | plugin.json, Claude compat, install paths (F5) |
| VS Code blog 2026-02 — Multi-agent | Native subagents, concurrency/depth (F6) |
| VS Code blog 2026-05 — Coding harness | Compaction, dynamic tools, model routing (F7) |
| agentskills.io + ecosystem reports | Cross-tool adoption (~40 tools) |
| Anthropic — Effective context engineering | Compaction, JIT, offload |
| GitHub Docs — cloud agent skills | Cloud-agent skill parity |
| Prior-art tables (v1 Appendix A) | Patterns only |

Forbid: copying community runtimes into office installs; hidden skill hijacks; always-on global instruction dumps.

---

## Document control

| Field | Value |
|---|---|
| Plan file | outputs/copilot_skills_pack_v2.plan.md |
| Status | REV 2 pending approval (v1 APPROVED baseline preserved §0.1) |
| v2 pass | 7 research-driven changes N1–N7 (standard-native skills, hooks control plane, native subagents, repo-as-plugin, frontmatter policy, upgrade lane, hook-evidenced golden path) |
| Nothing removed | v1 displaced items → Appendix B0 with reasons |
| Next step | User approves v2 → "execute the plan" → Phase 0 |
