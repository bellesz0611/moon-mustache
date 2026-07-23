# Changelog

## Unreleased

- continue external adoption work and release-over-release performance tracking
- add black-box CLI integration tests and enforce non-zero exit codes for strict failures
- add failure-contract tests for malformed manifests, invalid JSON, unsafe paths, report escaping, and missing variables
- raise the core coverage gate from 80% to 88% and fix accounting for fully covered files omitted by MoonBit's summary rows
- split the 2,048 differential cases across four fixed seeds and emit replayable JSON evidence
- add executable `mbt check` documentation and automated Markdown link validation
- pin imported `mustache/spec` provenance and enforce fixture, license, case-count, and generated-source integrity offline in CI
- add a controlled fault-injection matrix spanning rendering semantics, path safety, parent lookup, and all four resource guards; emit per-mutant JSON and JUnit evidence
- compare one reviewed output and diagnostics corpus directly across all four MoonBit backends
- expand deterministic differential parity to 6,144 cases and publish per-case JUnit XML
- expand executable documentation across sections, arrays, partials, strict diagnostics, and multi-file generation
- turn the browser playground into a bilingual compatibility lab with live reference comparison, pinned conformance details, and real five-file starter generation
- minimize differential failures automatically under a bounded evaluation budget and preserve reduced reproducers in JSON and JUnit evidence
- extract a side-effect-free CLI core, cover it independently, and enforce a separate 70% coverage gate alongside CLI black-box contracts
- update the playground to Vite 8, plugin-vue 6.0.8, and concurrently 9.2.4, and refresh maintained GitHub Actions to their Dependabot-proposed major versions; defer concurrently 10.0.3 because its pinned shell-quote version still triggers a high-severity advisory
- deploy the playground on every maintained-branch push so the published site and final submission evidence always identify the exact reviewed commit
- fetch full Git history in the main CI job so metrics provenance can verify its implementation commit instead of failing under a shallow checkout
- turn the Compatibility Lab Evidence view into a generated testing dashboard with layered metrics and per-mutant risk, detector, and status rows backed by a unit-tested view model

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
