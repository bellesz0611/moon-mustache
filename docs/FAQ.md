# FAQ

## Why build a Mustache engine for MoonBit?

MoonBit already has strong language and tooling foundations, but reusable text-generation infrastructure is still relatively sparse.

Many projects eventually need to turn structured data into text output for:

- scaffolding
- config rendering
- notifications
- static content
- report generation

Mustache is a good fit because it is:

- small and familiar
- easy to review
- widely known across ecosystems
- easier to trust than a custom ad hoc syntax

## Is this just a competition project?

No. The repository now includes:

- a published mooncakes.io package
- multiple CI workflows
- official fixture compatibility evidence
- downstream and adoption-oriented demo packages
- a Vue playground
- a static showcase site
- release-history, stability, and governance documentation

That does not guarantee long-term popularity, but it does mean the project is structured as a reusable package rather than a throwaway prototype.

## What is the safest API layer to depend on?

The safest current dependency surface is the core library rendering and bundle APIs described in `docs/API.md` and `docs/STABILITY.md`.

The CLI and report helpers are useful today, but they are still more likely to evolve before `1.0`.

## Does strict mode change Mustache rendering semantics?

No. Strict mode is designed to preserve rendered output while also surfacing missing-variable diagnostics.

That means teams can keep Mustache-compatible output behavior while still making CI or integration checks stricter.

## Why are missing variables rendered as empty output by default?

Because that matches the general spirit of Mustache and keeps the permissive render path predictable.

When stronger integration safety is needed, checked APIs and strict options can be used to collect diagnostics without changing the baseline output model.

## Why is there a CLI scan mode?

Because real consumers often need more than final output text.

Before integrating a template into a scaffold or config pipeline, it is useful to know:

- which variables are referenced
- which partials are required
- whether the template has parse diagnostics

The scan mode turns Moon Mustache into a small analysis tool as well as a renderer.

## Why are there multiple demos?

One demo can still look artificial.

The repository now includes multiple project surfaces so reviewers and adopters can see reuse in different forms:

- showcase output
- downstream consumer package
- adoption-oriented rollout demo
- Vue playground
- static site

## Is the package stable?

It is public and reusable today, but still pre-`1.0`.

The current expectation is:

- core rendering APIs should stay comparatively stable
- CLI ergonomics and report helpers may evolve faster
- public behavior shifts should be reflected in docs and changelog notes

See `docs/STABILITY.md` for the current stability tiers.
