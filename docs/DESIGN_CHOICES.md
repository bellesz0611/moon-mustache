# Design Choices

This document explains several important choices behind Moon Mustache so users understand not only what the project does, but why it does it that way.

## 1. Stay close to Mustache instead of inventing a bigger language

Moon Mustache intentionally keeps Mustache as the center of gravity.

Why:

- easier onboarding for users already familiar with Mustache
- easier reasoning about rendered output
- easier compatibility validation through upstream fixtures
- less long-term syntax maintenance burden

What this means in practice:

- the project prioritizes sections, partials, delimiters, escaping, and predictable lookup behavior
- the project avoids turning into a logic-heavy mini programming language

## 2. Separate stable core APIs from faster-evolving helper surfaces

Not every public surface should carry the same compatibility promise.

The repository therefore distinguishes between:

- core parsing and rendering APIs
- helper/reporting/competition-facing workflows
- CLI ergonomics

Why:

- downstream packages need a dependable core
- report helpers and human-facing outputs still benefit from iteration
- versioning becomes easier to explain

## 3. Keep checked rendering additive rather than disruptive

Checked APIs are designed to preserve rendered output while adding diagnostics.

Why:

- users often want observability without changing existing output behavior
- CI integrations can become stricter without forcing the whole application to change semantics
- the permissive and strict paths stay easier to compare

## 4. Treat compatibility evidence as a first-class feature

Moon Mustache does not only claim compatibility; it demonstrates it through:

- hand-written spec-style tests
- imported official `mustache/spec` fixtures
- dedicated report entrypoints

Why:

- trust matters more than feature lists for a template engine
- a smaller engine benefits from transparent validation
- evaluators and adopters both need concrete evidence

## 5. Expose multiple evaluator and adopter surfaces

The repository is intentionally not limited to core source files.

It also includes:

- CLI
- scenario reports
- downstream consumer proof
- adoption-oriented demo
- Vue playground
- static showcase site

Why:

- different users evaluate software differently
- some want code, some want commands, some want visual proof
- multiple surfaces reduce the risk that the project looks like an internal-only implementation

## 6. Prefer explicit bundle validation over magical file generation

Bundle rendering features include validation and generation-plan reporting instead of silently generating files from loosely defined state.

Why:

- file generation workflows are easier to trust when paths and outputs are inspectable
- validation helps catch duplicate or unsafe targets earlier
- CI integration becomes cleaner when there is a machine-reviewable plan

## 7. Accept a smaller scope in exchange for stronger reuse

Moon Mustache does not try to solve every text-generation problem.

It focuses on:

- stable reusable rendering
- predictable diagnostics
- adoption in scaffolding and config-style workflows

This smaller scope is intentional. A narrower tool with strong clarity is often more reusable in a young ecosystem than a broader tool with blurry boundaries.
