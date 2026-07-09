# Publishing Notes

## Current package metadata

- package: `bellesz0611/moon-mustache`
- version: `0.1.0`
- license: `MIT`
- release stage: pre-`1.0`
- mooncakes manifest API: `https://mooncakes.io/api/v0/manifest/bellesz0611/moon-mustache`
- mooncakes user API: `https://mooncakes.io/api/v0/user/bellesz0611`

## Current published state

- mooncakes.io publication for `0.1.0` has completed successfully
- packaged zip validation passed during `moon publish`
- server response returned `200 OK`
- build status reported by mooncakes API: `success`

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
10. Run `moon login` when publishing from a new machine
11. Run `moon publish`

## Current release-quality evidence

- `73` automated tests passing
- `136` imported official `mustache/spec` fixtures passing
- about `8791` MoonBit lines across reusable library, CLI, demos, reports, benchmarks, consumer demos, bridge code, and companion blueprint proof
- downstream consumer package smoke-tested
- bundle validation / plan mode available for CI preflight
- latest GitHub Actions release gate is green

## Publishing maintenance

When preparing the next release, keep these aligned:

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
- repository CI also includes compatibility gates for the older spellings `moon fmt --deny-warn` and `moon info --deny-warn`, while still running the current executable commands
- future `moon publish` runs on a new machine require a valid local credentials file created by `moon login`

## SemVer direction

- before `1.0`, public API cleanup is still allowed, but should be documented explicitly
- the rendering core should stabilize first
- report helpers and CLI ergonomics can continue evolving more quickly than the library core
