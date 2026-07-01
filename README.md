# Moon Mustache

Moon Mustache is a Mustache template engine implementation for MoonBit.

## Why this project

MoonBit already has a strong language core and toolchain, but reusable template
rendering is still a missing piece in the ecosystem. Many practical tools need
to turn structured data into text output:

- project scaffolding
- configuration generation
- static content rendering
- email and notification templates
- code generation helpers

This project focuses on a small, stable, reusable core instead of building a
feature-heavy template language.

## Stage-one scope

The first milestone focuses on:

- repository and module scaffolding
- parser and renderer architecture
- core Mustache syntax coverage planning
- early examples and compatibility notes
- test layout for spec-driven development

## Planned features

- tokenization and parsing for Mustache templates
- AST-based rendering pipeline
- context stack and dotted path lookup
- sections, inverted sections, comments, partials, and delimiter changes
- escaped and unescaped value rendering
- file-oriented rendering helpers
- a small CLI for local template rendering

## Reference projects

- [mustache.js](https://github.com/janl/mustache.js)
- [mustache/spec](https://github.com/mustache/spec)

## Repository status

This repository is in active bootstrap. Early commits focus on project
structure, design notes, and minimal MoonBit code skeletons that will be
expanded into a reusable library.
