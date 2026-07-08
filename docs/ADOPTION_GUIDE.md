# Adoption Guide

This guide is for teams considering Moon Mustache as a dependency in a real MoonBit project.

## Good fit scenarios

Moon Mustache is a strong fit when your project needs:

- template-based scaffolding
- configuration or manifest rendering
- release note or email generation
- lightweight HTML or Markdown fragment generation
- multi-file output from one shared context

## Recommended adoption path

1. Start with core library rendering APIs from `docs/API.md`.
2. Use checked rendering early in integration work.
3. Turn on strict options in CI-style verification paths.
4. Introduce bundle rendering when multiple files share context or partials.
5. Use the CLI for local template experiments and quick regression checks.

## Start small

For many teams the easiest first step is:

- render one template from JSON
- add partial support when fragments repeat
- adopt bundle manifests only when multi-file workflows appear

This keeps the integration understandable and avoids premature complexity.

## Recommended verification

Before depending on the package in a larger workflow, verify:

- your target templates render as expected
- missing-variable behavior matches your expectations
- checked diagnostics fit your CI or local tooling needs
- output paths are validated if you use bundle generation

## Repository entrypoints worth exploring

- `downstream_consumer/`
  release communication bundle example
- `adoption_demo/`
  operations rollout kit example
- `content_pipeline_demo/`
  documentation/content generation example
- `playground/`
  browser-facing exploration surface

## When not to choose Moon Mustache

You may want something else when:

- you need a logic-heavy template language
- you want template execution to include custom computation semantics
- your workflow is so small that plain string construction is clearer

Moon Mustache is strongest when a project benefits from a smaller, predictable, cross-ecosystem syntax.
