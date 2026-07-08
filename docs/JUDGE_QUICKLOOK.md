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

- about `7352` MoonBit LOC across library, CLI, demos, reports, benchmarks, consumer demos, and bridge code
- about `5839` handwritten MoonBit LOC
- `1513` lines of imported generated official fixture asset
- `35+` public commits
- `64 / 64` automated tests passing
- `136 / 136` imported official `mustache/spec` fixtures passing
- latest GitHub library CI and playground smoke workflows are green on the default branch

## 3. Core capabilities

- scanner, parser, AST, and renderer
- escaped and unescaped interpolation
- sections and inverted sections
- comments, partials, and delimiter changes
- dotted lookup, current-context lookup, and array iteration
- strict missing-variable diagnostics
- template reference scanning through library APIs and CLI
- bundle manifest rendering, validation, and plan generation
- official spec compatibility reporting
- downstream consumer reuse proof
- second adoption-oriented rollout demo package
- content-pipeline consumer demo package
- Vue playground demo backed by the repository's own MoonBit engine
- independent playground build and API-bridge smoke workflow
- repository governance and support documents for longer-term maintainability
- static site deployment workflow for a lightweight public-facing showcase
- benchmark snapshot documentation for regression-oriented review
- release-history documentation showing the recent project maturation path
- FAQ and design-choice documentation explaining project boundaries and rationale

## 4. Fastest verification path

Run the following commands:

```bash
moon test --deny-warn
moon run showcase
moon run official_spec_report
moon run cli --template "{{#user}}{{name}}{{/user}}{{> footer}}" --scan
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
- mooncakes.io publication for `0.1.0` is complete

The remaining work is now about future releases and continued ecosystem polish, not first-time publication.
