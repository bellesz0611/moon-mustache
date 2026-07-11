# Release History

This page summarizes how Moon Mustache moved from a competition bootstrap repository into a more complete MoonBit ecosystem package.

## Current release

- package: `bellesz0611/moon-mustache`
- current published version: `0.2.0`
- publication state: published on mooncakes.io
- release posture: pre-`1.0`, but already public and reusable

## Milestone timeline

| Date | Commit | Milestone | Why it mattered |
| --- | --- | --- | --- |
| `2026-07-07` | `132a22a` | aligned CI with MoonBit `0.10.3` guidance | matched competition expectations more closely |
| `2026-07-07` | `295a915` | migrated to `moon.mod` and enforced `moon fmt --check` | improved package readiness and tooling hygiene |
| `2026-07-07` | `08d1310` | added template scan API and tightened CI validation | expanded beyond plain rendering into analysis-oriented tooling |
| `2026-07-07` | `9ecfbe6` | switched CI to the official MoonBit installer | reduced CI fragility and aligned with official guidance |
| `2026-07-08` | `2eb22cf` | polished evaluator-facing presentation | improved review friendliness and documentation clarity |
| `2026-07-08` | `46f7b15` | updated docs for mooncakes publication | reflected the project as a published package instead of a local-only repo |
| `2026-07-08` | `4e9fbd6` | elevated playground and repository health | turned the browser demo into a stronger public-facing project surface |
| `2026-07-08` | `b61665d` | strengthened governance and release posture | made the repository look and behave more like a maintainable open-source project |
| `2026-07-08` | `cf855a2` | added a public showcase site and comparison docs | created a lightweight evaluator landing page |
| `2026-07-08` | `666f144` | expanded adoption demos and visual showcase assets | made reuse and project surfaces easier to see at a glance |
| `2026-07-09` | `631756c` | prepared manifest rendering and templated bundle paths | moved compile-once rendering into real manifest workflows and made generated file paths truly runtime-aware |
| `2026-07-10` | `0.2.0` | optional specs, diagnostics, safety, differential tests, and browser ESM | moved from a strong core engine to a release-grade, externally verifiable package |

## Release themes so far

The current repository evolution has concentrated on four themes:

1. Core Mustache capability
2. Evidence and compatibility
3. Public-facing demonstration
4. Long-term maintainability

## What makes `0.2.0` meaningful

`0.2.0` builds on the usable `0.1.0` base and adds:

- complete core and optional upstream fixture parity (`194 / 194`)
- structured diagnostics, lint, and render resource limits
- deterministic differential testing against `mustache.js`
- an enforced core coverage threshold with machine-readable reports
- four-backend CI and a dedicated Windows regression job
- a Vue playground executing the MoonBit-compiled engine directly in the browser

## Next release direction

If the project continues beyond the current competition stage, likely follow-up release themes include:

- richer benchmark history across versions
- more external adoption examples
- more automation around upstream fixture sync
- continued tightening of diagnostics and release notes
