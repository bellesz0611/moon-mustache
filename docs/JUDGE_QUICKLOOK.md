# Judge Quick Look

This page is a short evaluator-facing entrypoint for Moon Mustache.

## 1. What the project is

Moon Mustache is a reusable Mustache template engine for MoonBit. It targets practical engineering workflows such as:

- scaffolding and multi-file project generation
- configuration and manifest rendering
- documentation and message template generation
- reusable embedding from downstream MoonBit packages

The project is intentionally focused on Mustache core semantics and engineering reuse, rather than growing into a custom logic-heavy template language.

## 2. Why it is not a shell repository

- about `8032` handwritten effective MoonBit LOC, inside the suggested competition band
- about `2149` imported generated fixture effective lines, disclosed separately
- public history already exceeds the required `10-20` meaningful commits
- `85 / 85` automated tests passing
- `194 / 194` imported core and optional `mustache/spec` fixtures passing, zero skipped
- `2048 / 2048` deterministic differential cases passing against `mustache.js`
- `81.5%` core coverage with an enforced `80%` CI gate
- latest GitHub library CI and playground smoke workflows are green on the default branch

For the exact current numbers, prefer `docs/METRICS_SNAPSHOT.md`.

## 3. Core capabilities

- scanner, parser, AST, and renderer
- escaped and unescaped interpolation
- sections and inverted sections
- comments, partials, and delimiter changes
- dynamic partial names, parent/block inheritance, and native MoonBit lambdas
- dotted lookup, current-context lookup, and array iteration
- strict missing-variable diagnostics
- structured source diagnostics, lint, and deterministic render resource limits
- template reference scanning through library APIs and CLI
- bundle manifest rendering, validation, and plan generation
- prepared rendering and prepared manifest profile workflows
- rendered bundle output paths with runtime validation
- official spec compatibility reporting
- downstream consumer reuse proof
- operations-rollout consumer demo package
- content-pipeline consumer demo package
- starter-repository consumer demo package
- incident-response consumer demo package
- developer-release consumer demo package
- companion-repo blueprint for near-standalone consumer shape
- Vue playground directly executing the MoonBit-compiled ES module
- independent Linux and Windows playground build/API-bridge smoke workflows
- repository governance and support documents for longer-term maintainability
- GitHub Pages deployment workflow for a directly runnable public playground
- benchmark snapshot documentation for regression-oriented review
- release-history documentation showing the recent project maturation path
- FAQ and design-choice documentation explaining project boundaries and rationale
- communication and submission support documents for outreach and judge-facing explanation, including a dedicated artifact index

## 4. Fastest verification path

Run the following commands:

```bash
moon test --deny-warn
moon run showcase
moon run official_spec_report
moon run cli --template "{{#user}}{{name}}{{/user}}{{> footer}}" --scan
cd playground && npm ci && npm run differential
```

What these prove:

- `moon test --deny-warn`
  regression safety and clean diagnostics
- `moon run showcase`
  realistic rendering scenarios beyond unit tests
- `moon run official_spec_report`
  explicit upstream `mustache/spec` compatibility evidence
- `moon run cli ... --scan`
  analysis-oriented functionality beyond simple string rendering

## 5. Why it matters for MoonBit

MoonBit still has room for more reusable text-generation infrastructure. This project contributes a practical middle layer:

- lighter than building custom generators for every tool
- more reusable than ad hoc string concatenation
- easier to adopt because Mustache semantics are familiar across ecosystems
- suitable as a dependency for future MoonBit scaffolding, documentation, config, and codegen tools

## 6. Current release state

The repository is already in a strong acceptance and release state:

- local `fmt / info / check / test` gates pass
- latest GitHub CI is green
- GitHub and GitLink are synchronized
- mooncakes.io publication for `0.2.0` is complete
- the browser playground is deployed through GitHub Pages

The remaining work is now about future releases and continued ecosystem polish, not first-time publication.
