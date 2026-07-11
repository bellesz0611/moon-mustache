# Official Spec Integration

Moon Mustache now imports official fixtures from the upstream [mustache/spec](https://github.com/mustache/spec) repository instead of relying only on hand-written spec-style cases.

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

## Generation flow

The generated MoonBit fixture source lives in [src/official_spec_fixtures.mbt](../src/official_spec_fixtures.mbt).

Refresh it with:

```bash
python scripts/generate_official_spec_fixtures.py
```

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
