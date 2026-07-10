# Adoption Evidence

This document summarizes the current consumer-style proof surfaces included in the repository.

## Why this page exists

One common weakness in contest projects is that they look self-contained: the core package works, but there is little proof that another project would really adopt it.

Moon Mustache now includes multiple consumer-style demos to reduce that concern.

## Current consumer-style demos

### 1. `downstream_consumer/`

Focus:

- release communication bundle generation
- profile-aware bundle rendering
- validation and bundle-plan reporting

Why it matters:

- shows reuse from a separate MoonBit package
- demonstrates a practical release-workflow scenario

### 2. `adoption_demo/`

Focus:

- operations rollout kit generation
- environment-style multi-file output
- validation and bundle-plan reporting

Why it matters:

- proves the library is not tied to documentation-only output
- demonstrates another real workflow family

### 3. `content_pipeline_demo/`

Focus:

- Markdown overview generation
- announcement text generation
- HTML fragment generation

Why it matters:

- demonstrates content-production style output
- shows the same engine serving multiple artifact formats

### 4. `starter_repo_demo/`

Focus:

- starter repository scaffolding
- generated `README.md`, `moon.mod`, `.gitignore`, and starter source file

Why it matters:

- aligns directly with common MoonBit ecosystem tooling needs
- makes the project feel closer to a reusable engineering dependency

### 5. `incident_response_demo/`

Focus:

- incident runbook generation
- status-page draft generation
- escalation contact packaging

Why it matters:

- shows the engine serving urgent operational coordination flows
- demonstrates another multi-file bundle domain beyond rollout scaffolding

### 6. `developer_release_demo/`

Focus:

- GitHub release body generation
- install / upgrade snippet generation
- migration summary generation

Why it matters:

- shows the same core helping with developer-facing publishing work
- broadens the adoption story beyond internal ops and content workflows

## Workflow support

These proof surfaces are not documentation-only.

They are now exercised through:

- the main CI workflow
- release-readiness artifact generation
- a dedicated consumer-proof workflow

## What this still does not prove

These demos are strong internal adoption evidence, but they are still maintained in the main repository.

That means they are not identical to:

- independently maintained external repositories
- community-submitted integrations
- long-lived third-party adopters

Still, they significantly strengthen the repository's reuse story compared with a single demo or tests-only package.
