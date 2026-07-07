# Release Checklist

## Before tagging

- `moon check`
- `moon test`
- `moon run --target js cli --template-file ... --json-file ...`
- `moon run scenario_report`
- `moon run official_spec_report`
- `moon run downstream_consumer`
- `moon run --target js cli --bundle-manifest-file ... --bundle-check-only ...`
- refresh compatibility notes if behavior changed
- update README examples if CLI flags changed
- update `CHANGELOG.md`

## Before competition submission update

- verify GitHub and GitLink repositories stay in sync
- ensure CI is green on the current branch
- include benchmark output snapshot
- refresh `docs/SPEC_COVERAGE.md`
- refresh `docs/COMPATIBILITY.md`
- refresh `docs/OFFICIAL_SPEC.md`
- refresh `docs/PUBLISHING.md`
- refresh `docs/EVALUATION_SUMMARY.md`

## Before mooncakes.io publishing

- stabilize public API names
- confirm package metadata in `moon.mod`
- document supported targets and current file IO limitations
- prepare semver policy and changelog notes
