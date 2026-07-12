# SkillsForge — Seven pillars

**20% Change. 80% Better.**

| # | Pillar | Test |
|---|--------|------|
| 1 | One standard, many harnesses | Body-transform per agent? No |
| 2 | Code over vibes | Logic only in prose? Codify |
| 3 | Context thrift | Always-on dumps? Reject |
| 4 | Ask → confirm → finish | Build before confirm? No |
| 5 | Parallel safe, sequential sacred | Safety path parallel? No |
| 6 | Measure → learn → promote | Degrade promote? Refuse |
| 7 | Secrets stay local | Leak? Block — see expansion below |

Conflict order: correctness > thrift · safety > speed · evidence > hype · native > custom · upgrade > silent overwrite.

## Pillar 7 expansion (secrets & personal data)

Canonical detail: `KnowledgeVault/_templates/NEW_PROJECT_INSTRUCTIONS.md` §10.

| Must stay out of git | Examples |
|----------------------|----------|
| Secrets | `.env`, API keys, tokens, cookies, private keys |
| Credentials | Passwords, encrypted vault dumps committed by mistake |
| PII / tax docs | PAN, Form 16, AIS, broker P&L, ITR JSON, filled profile YAML |
| Runtime stores | `data/**`, SQLite `*.db`, local ledgers with real identities |

**Allowed:** redacted `*.example.*`, fake `tests/fixtures/`, `.env.example` with empty placeholders.

**Agent test:** About to `git add` a vault file, real PAN, or `.env`? → **Block.** Prefer secrets-audit script before push.
