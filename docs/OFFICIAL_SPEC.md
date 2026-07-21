# Official Spec Integration

Moon Mustache imports official fixtures from upstream [mustache/spec](https://github.com/mustache/spec) instead of relying only on hand-written spec-style cases. The local corpus is pinned to upstream commit [`e8ec001db7f594521e773c34866aca2b5d6b0037`](https://github.com/mustache/spec/tree/e8ec001db7f594521e773c34866aca2b5d6b0037) from 2026-04-27.

## Imported suites

- `comments.json`
- `delimiters.json`
- `interpolation.json`
- `inverted.json`
- `partials.json`
- `sections.json`
- `~dynamic-names.json`
- `~inheritance.json`
- `~lambdas.json`

These files are stored under [third_party/mustache-spec/specs](../third_party/mustache-spec/specs).

The preserved upstream license text is stored under [third_party/mustache-spec/LICENSE](../third_party/mustache-spec/LICENSE), and repository-level attribution is summarized in [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

The imported JSON values are semantically identical to the pinned upstream commit; local whitespace formatting may differ. [MANIFEST.json](../third_party/mustache-spec/MANIFEST.json) records every local file's UTF-8/LF-normalized SHA-256 and case count, the license checksum, the generated source checksum, and the upstream identity used for the comparison.

## Generation flow

The generated MoonBit fixture source lives in [src/official_spec_fixtures.mbt](../src/official_spec_fixtures.mbt).

Refresh it with:

```bash
python scripts/generate_official_spec_fixtures.py
```

Then verify that the manifest, fixture corpus, license, suite order, case counts, and generated MoonBit source still agree:

```bash
python scripts/verify_official_spec_fixtures.py
```

This integrity check is offline and runs in local acceptance, the main CI workflow, and release readiness. CI therefore does not depend on upstream network availability, while fixture drift or a stale generated file still fails the build.

## Current posture

- Imported official cases: `194`
- Passing imported cases: `194`
- Explicitly skipped imported cases: `0`

## Reporting

Run:

```bash
moon run official_spec_report
```

This produces a Markdown compatibility report that separates:

- passing official cases
- failing official cases
- explicitly skipped official cases with reasons

At the current project state, the report is expected to show:

- `194` passing cases
- `0` failing cases
- `0` skipped cases
