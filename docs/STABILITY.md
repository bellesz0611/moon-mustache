# Stability Policy

Moon Mustache is currently a pre-`1.0` package, but it already separates its surface into stability tiers.

## Stability tiers

### Tier 1: Core library APIs

These are the APIs downstream packages should build against first:

- parsing
- checked and unchecked string rendering
- partial rendering
- JSON context helpers
- bundle rendering
- bundle validation
- bundle planning

Expectation:

- changes should stay source-compatible whenever practical
- behavior changes should be justified by Mustache spec alignment or clear bug fixes
- if an API needs redesign, prefer adding a replacement before removing the old shape

### Tier 2: Companion workflow helpers

These helpers are useful, but more likely to evolve:

- Markdown / JSON report formatters
- scenario report entrypoints
- competition-facing compatibility report helpers

Expectation:

- output wording and report structure may still improve
- helper naming can be refined before a `1.0` release

### Tier 3: CLI UX

The CLI is intended to be practical today, but is still evolving in:

- command ergonomics
- diagnostics wording
- bundle-oriented workflow shortcuts

Expectation:

- flags may expand
- help text and default messaging can change
- file-backed behavior remains constrained by current target support

## Versioning direction

- current package stage: `0.1.x`
- before `1.0`, breaking changes are still possible, but should be documented clearly
- after `1.0`, core library APIs should follow SemVer-style compatibility expectations

## Behavior promises already in place

- missing variables render as empty output in permissive rendering
- checked rendering preserves output while exposing diagnostics
- official `mustache/spec` compatibility is treated as a first-class regression signal
- recursive partial expansion is guarded by a depth limit

## What must stabilize before `1.0`

- final public API naming boundaries
- target support statement for file workflows
- report helper surface that should remain public
- mooncakes.io publishing and release cadence
