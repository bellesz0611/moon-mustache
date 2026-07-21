# Repository guidance for coding agents

Moon Mustache is a reusable MoonBit Mustache engine. Preserve its compatibility evidence and treat generated metrics as claims that must remain reproducible.

## Before changing code

- Read `README.md` for the product path and `docs/ARCHITECTURE.md` for component boundaries.
- Keep core rendering semantics aligned with `mustache/spec`; optional extensions must not change core behavior.
- Do not hand-edit counts in `docs/METRICS_SNAPSHOT.md` or `docs/METRICS_SNAPSHOT.json`. Regenerate both with `python scripts/generate_metrics_snapshot.py`.
- Never present imported fixtures, differential inputs, and MoonBit test cases as one summed “test count”.

## Implementation rules

- Add a focused regression test before or with every behavior fix.
- Prefer black-box tests for public contracts. Use `_wbtest.mbt` only for internal branches that public APIs cannot construct, such as failure-report formatting.
- CLI failures that block or invalidate output must return a non-zero process exit code.
- Keep file-backed CLI behavior on the `js` target unless the filesystem architecture is intentionally changed.
- Preserve fixture provenance and license files under `third_party/mustache-spec/`.
- Avoid unrelated generated demos or vanity metrics; strengthen one end-to-end user task instead.

## Verification

Run the smallest relevant command while iterating, then use:

```bash
python scripts/verify.py
```

Before release-oriented changes or a final handoff, run:

```bash
python scripts/verify.py --profile full
```

The full profile may mark native build/test as skipped when no local C compiler exists. GitHub Actions must still execute the native lane.

For focused evidence:

```bash
python scripts/test_cli_integration.py
python scripts/verify_official_spec_fixtures.py
python scripts/run_coverage.py --minimum 88 --cli-core-minimum 70
python scripts/run_fault_injection.py
python scripts/test_backend_conformance.py
cd playground && npm run differential
```

## Documentation and evidence

- Run `python scripts/check_docs.py` after changing Markdown links.
- Run `python scripts/check_metrics_freshness.py` after regenerating the canonical metrics snapshot.
- Keep README product-oriented. Competition-specific claims belong in `docs/SPECIAL_AWARD_EVIDENCE.md`.
- Link to the canonical metrics snapshot instead of copying volatile counts into multiple documents.
- Machine-readable evidence belongs in ignored `_artifacts/` locally and uploaded CI artifacts remotely.

## AI-assisted changes

- Record assumptions, failing checks, and reviewer-sensitive tradeoffs in the PR or commit message.
- Human review owns the final decision; an agent passing tests is not approval.
- Never fabricate prompts, reviews, issues, adoption, CI runs, or benchmark history.
- Disclose meaningful AI assistance when it influenced design or implementation, and identify the verification performed afterward.
