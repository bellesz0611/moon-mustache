# Publishing Notes

## Current package metadata

- package: `bellesz0611/moon-mustache`
- version: `0.2.0`
- license: `MIT`
- release stage: pre-`1.0`
- mooncakes manifest API: `https://mooncakes.io/api/v0/manifest/bellesz0611/moon-mustache`
- mooncakes user API: `https://mooncakes.io/api/v0/user/bellesz0611`

## Current published state

- mooncakes.io documentation for `0.2.0` is publicly reachable
- packaged zip validation passed during `moon publish`
- server response returned `200 OK`
- package docs URL: `https://mooncakes.io/docs/bellesz0611/moon-mustache%400.2.0`

## Recommended release flow

1. Run `moon fmt --check` and `moon info --target all`
2. Run `moon check --deny-warn --target all` and `moon test --deny-warn --target all`
3. Run `moon run spec_report`
4. Run `moon run official_spec_report`
5. Run `moon run scenario_report`
6. Run `moon run downstream_consumer`
7. Run the `js` CLI smoke tests for file and bundle flows
8. Run `cd playground && npm ci && npm run differential && npm run build`
9. Update `CHANGELOG.md`
10. Tag the release
11. Run `moon login` when publishing from a new machine
12. Run `moon publish`

## Current release-quality evidence

- `85` automated tests passing
- `194` imported core and optional `mustache/spec` fixtures passing
- `2048` deterministic differential cases passing against `mustache.js`
- `8032` handwritten effective MoonBit lines, with generated fixtures disclosed separately
- `81.5%` core coverage with an enforced `80%` CI gate
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
- repository CI uses the corrected `moon fmt --check` command and retains an `moon info --deny-warn` compatibility fallback for toolchains where that spelling exists
- future `moon publish` runs on a new machine require a valid local credentials file created by `moon login`

## SemVer direction

- before `1.0`, public API cleanup is still allowed, but should be documented explicitly
- the rendering core should stabilize first
- report helpers and CLI ergonomics can continue evolving more quickly than the library core
