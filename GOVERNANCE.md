# Governance

## Project scope

Moon Mustache is a reusable Mustache template engine for MoonBit, with supporting CLI, compatibility reports, bundle-generation helpers, and a browser-facing demo surface.

The project is intentionally scoped around:

- stable Mustache semantics
- practical MoonBit ecosystem reuse
- compatibility evidence
- diagnostics and tooling support

The project is intentionally not focused on:

- inventing a new logic-heavy template language
- accumulating unrelated text-generation features that weaken compatibility

## Current maintainer model

At the current stage, the project uses a maintainer-led model.

The maintainer is responsible for:

- release decisions
- compatibility direction
- CI and publishing health
- triaging issues and pull requests
- keeping GitHub and GitLink synchronized for competition requirements

## Decision principles

Changes are preferred when they improve one or more of the following:

- compatibility with Mustache expectations
- clarity of diagnostics
- reuse from downstream MoonBit packages
- release confidence and CI coverage
- evaluator and adopter understandability

Changes may be rejected when they:

- introduce hard-to-explain syntax
- reduce compatibility evidence
- create maintenance cost without ecosystem value
- duplicate features better handled outside the core library

## Release posture

The repository tracks stable public package publication through mooncakes.io and keeps release notes in `CHANGELOG.md`.

Major behavior shifts should be documented in:

- `CHANGELOG.md`
- `README.md`
- compatibility or API docs when relevant

## Future evolution

If the contributor base grows, the project can evolve toward a broader maintainer group with clearer area ownership for:

- core rendering
- CLI and bundle workflows
- compatibility fixtures and reports
- playground and external demos
