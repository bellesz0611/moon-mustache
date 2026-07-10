# Comparison Notes

This document explains how Moon Mustache should be understood relative to nearby alternatives in the MoonBit ecosystem and in general engineering practice.

## 1. Compared with ad hoc string concatenation

Ad hoc string building is quick for tiny one-off outputs, but it scales poorly when a project needs:

- reusable fragments
- optional blocks
- stable escaping behavior
- diagnostics for missing data
- multiple output files driven by one shared context

Moon Mustache improves this by offering:

- a stable Mustache syntax already familiar across ecosystems
- partials for reusable fragments
- sections and inverted sections for optional structure
- checked rendering with missing-variable diagnostics
- bundle rendering and validation helpers for multi-file workflows

## 2. Compared with writing a custom template mini-language

A custom template language can look attractive in the short term, but it often creates long-term costs:

- harder onboarding for users
- unclear compatibility expectations
- higher maintenance burden
- more debates about syntax growth

Moon Mustache deliberately stays close to Mustache semantics so the project can optimize for:

- predictability
- easier review
- easier downstream adoption
- compatibility evidence through imported upstream fixtures

## 3. Compared with a contest-only prototype

A contest-only prototype usually stops at:

- a parser or renderer core
- a few local tests
- a short README

Moon Mustache currently goes further by including:

- a reusable MoonBit package published on mooncakes.io
- CLI and bundle rendering workflows
- official `mustache/spec` fixture imports and reports
- scenario and downstream-consumer proofs
- a Vue playground backed by the repository's own MoonBit engine
- CI workflows for library checks, playground smoke tests, and release-readiness artifacts
- governance, contribution, support, and security documents

## 4. Compared with the existing MoonBit Mustache attempt

MoonBit 生态里已经有同类方向的公开项目，例如:

- mooncakes: <https://mooncakes.io/docs/ryota0624/mustache>
- GitHub: <https://github.com/ryota0624/moonbit-mustache>

Moon Mustache does not try to claim that no similar experiment exists. Its independent contribution is that it pushes the same direction much further toward competition-grade engineering reuse:

- broader compatibility evidence through imported official `mustache/spec` fixtures
- a reusable CLI and bundle-generation workflow rather than library-only rendering
- multiple downstream consumer demos instead of a single embedded example
- stronger review surface through CI, benchmark artifacts, static site packaging, and evaluator-facing indexes
- clearer publication and maintenance posture through mooncakes release plus governance/support documents

## 5. Compared with logic-heavy template engines

Some template systems provide more control-flow or embedded logic, but that is not the goal here.

Moon Mustache intentionally chooses a smaller and stricter surface area because the target use cases are:

- scaffolding
- config rendering
- report generation
- notifications and email bodies
- static content assembly

For these workflows, smaller syntax often means:

- fewer surprising behaviors
- easier review of generated output
- clearer portability across ecosystems

## 6. Why this matters specifically for MoonBit

MoonBit already has strong language and tooling foundations, but reusable text-generation infrastructure is still relatively sparse.

Moon Mustache contributes a middle layer that sits between:

- raw string concatenation
- project-specific generators
- heavier external templating systems

That makes it useful as a shared dependency for future MoonBit tools rather than a one-off application detail.
