# Changelog

## Unreleased

- continue external adoption work and release-over-release performance tracking

## 0.2.0 - 2026-07-10

- complete all 194 imported core and optional `mustache/spec` fixtures, including dynamic partial names, template inheritance, and lambdas
- add stable structured diagnostics with error codes, source spans, line/column positions, and excerpts
- add library and CLI linting for syntax, missing variables, unresolved partials, partial cycles, invalid JSON, and unsafe bundle paths
- add configurable output, iteration, render-step, and partial-depth resource limits
- add a deterministic 2,048-case differential suite against `mustache.js`; the suite found and now guards a repeated HTML escaping regression
- enforce at least 80% core coverage and publish Cobertura plus summary artifacts in CI
- validate `wasm`, `wasm-gc`, `js`, and `native` backends with explicit check, build, and test stages
- pin MoonBit `0.10.3+16975d007` and verify the installed compiler in every workflow
- compile the MoonBit renderer to an ES module used directly by the Vue browser playground
- add GitHub Pages deployment and a dedicated Windows browser/API bridge regression job

## 0.1.0

- initial MoonBit Mustache rendering core
- scanner, parser, AST, dotted lookup, `{{.}}`, sections, inverted sections, comments, partials, and delimiter changes
- template reference scanning APIs and CLI scan mode
- JSON rendering helpers and checked render options with missing-variable diagnostics
- bundle rendering APIs, manifest profiles, validation, and generation plans
- CLI support for single-template rendering, file-based flows, and bundle workflows
- official `mustache/spec` fixture import and compatibility report generation
- scenario report, benchmark entrypoint, downstream consumer, and adoption-oriented demo packages
- Vue playground backed by the repository's own MoonBit engine
- library CI, playground smoke, release-readiness, and site deployment workflows
- mooncakes.io publication for `bellesz0611/moon-mustache@0.1.0`
