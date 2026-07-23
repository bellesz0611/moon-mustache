# Dependency Review

Reviewed on 2026-07-23 for the competition submission branch.

## Accepted updates

| Component | Selected version | Validation |
| --- | --- | --- |
| `actions/checkout` | `v7` | maintained workflows and generated starter workflow updated |
| `actions/setup-node` | `v7` | playground, site, and release-readiness workflows updated |
| `actions/upload-artifact` | `v7` | CI, consumer proof, playground, and release artifacts updated |
| `vite` | `8.1.5` | production build and browser smoke test pass |
| `@vitejs/plugin-vue` | `6.0.8` | production build and browser smoke test pass |
| `vue` | `3.5.40` | Evidence view-model tests, production build, and browser smoke test pass |
| `concurrently` | `9.2.4` | retained on the secure Node 18-compatible major |

## Deliberate exception

Dependabot PR [#3](https://github.com/bellesz0611/moon-mustache/pull/3) proposes
`concurrently` 10.0.3. That release pins `shell-quote` 1.8.4, which triggers a
high-severity `npm audit` advisory in this dependency graph. Version 9.2.4 uses
`shell-quote` 1.9.0 and leaves the audited production and development tree with
zero known vulnerabilities. The major update is therefore deferred rather than
merged mechanically.

## Reproduction

```bash
cd playground
npm ci
npm audit --audit-level=high
npm run test:differential-minimizer
npm run differential
npm run build
npm run smoke
```

The repository-wide `python scripts/verify.py --profile full` command repeats
the relevant dependency, differential, build, and smoke checks as part of the
final evidence gate.
