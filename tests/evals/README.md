# L3/L4 evals

## Merge-blocking (CI)

- **L3 static markers:** `shared/fixtures/l3-static-markers.json` via `Test-Phase7`
- **L4 ICS:** `shared/fixtures/l4-quality-cases.json` + baseline via `Test-Phase8`

## Optional (never sole promote/merge gate)

```bash
# npx promptfoo@latest eval -c tests/evals/promptfoo.yaml          # static mirror
# npx promptfoo@latest eval -c tests/evals/promptfoo-llm.yaml      # needs OPENAI_API_KEY
```

GitHub: `.github/workflows/quality-judge.yml` (`continue-on-error`).

## Policy

- L1/L2/L3-static/L4-ICS: required in CI
- LLM-judge: optional signal only until noise floor proven
