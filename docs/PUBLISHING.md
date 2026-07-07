# Publishing Notes

## Current package metadata

- package: `bellesz0611/moon-mustache`
- version: `0.1.0`
- license: `MIT`
- release stage: pre-`1.0`

## Recommended release flow

1. Run `moon check`
2. Run `moon test`
3. Run `moon run spec_report`
4. Run `moon run official_spec_report`
5. Run `moon run scenario_report`
6. Run `moon run downstream_consumer`
7. Run the `js` CLI smoke tests for file and bundle flows
8. Update `CHANGELOG.md`
9. Tag the release
10. Run `moon login`
11. Run `moon publish`

## Current release-quality evidence

- `61` automated tests passing
- `136` imported official `mustache/spec` fixtures passing
- about `6030` MoonBit lines across reusable library, CLI, demos, reports, and benchmarks
- downstream consumer package smoke-tested
- bundle validation / plan mode available for CI preflight

## Publishing readiness

Before publishing to mooncakes.io, keep these aligned:

- `moon.mod`
- `README.md`
- `CHANGELOG.md`
- `docs/COMPATIBILITY.md`
- `docs/OFFICIAL_SPEC.md`
- `docs/EVALUATION_SUMMARY.md`
- `docs/STABILITY.md`
- `docs/BENCHMARKS.md`

## Mooncakes note

- local packaging is ready once `moon fmt --check`, `moon info`, `moon check --deny-warn`, and `moon test --deny-warn` all pass
- actual `moon publish` requires a valid local credentials file created by `moon login`

## SemVer direction

- before `1.0`, public API cleanup is still allowed, but should be documented explicitly
- the rendering core should stabilize first
- report helpers and CLI ergonomics can continue evolving more quickly than the library core
