# Use Cases

Moon Mustache is aimed at practical MoonBit ecosystem scenarios where structured data must become text output.

## 1. Configuration generation

Typical need:

- deployment config stubs
- local development config snapshots
- CI or service manifest generation

Why Moon Mustache helps:

- templates stay logic-light
- data can come from JSON or MoonBit values
- checked rendering can surface missing partials before files are emitted
- bundle rendering APIs can generate multiple related files from one context

## 2. Notification and email templates

Typical need:

- onboarding messages
- release notifications
- system alert bodies

Why Moon Mustache helps:

- repeated layout fragments can live in partials
- HTML-escaped interpolation is safe by default
- sections handle optional blocks without a heavier template language
- strict render options can surface missing placeholders during integration testing

## 3. Static text and HTML snippet generation

Typical need:

- documentation fragments
- status dashboards
- changelog summaries

Why Moon Mustache helps:

- deterministic output
- simple loops for repeated cards or rows
- stable enough to plug into lightweight static pipelines
- compatibility reports make it easier to trust behavior across project upgrades

## 4. Project scaffolding

Typical need:

- generate starter files from metadata
- keep a shared set of reusable template fragments

Why Moon Mustache helps:

- partials naturally model reusable file fragments
- JSON bundle helpers fit metadata-driven generation flows
- CLI file mode already demonstrates the template + JSON + partials pipeline
- `render_template_bundle_checked(...)` gives library consumers a reusable multi-file generation entrypoint

## 5. Template project profiles

Typical need:

- switch between dev / test / prod outputs
- share one template set while varying ports, banners, or footer fragments

Why Moon Mustache helps:

- bundle manifests can define base context once
- profiles can override context and partials without duplicating every template file
- the CLI can render a selected profile and export a machine-readable report

## 6. CI preflight for generated artifacts

Typical need:

- fail fast on unsafe output paths
- review what files would be generated before writing them
- produce audit-friendly validation and plan reports in CI

Why Moon Mustache helps:

- path normalization blocks traversal-like output paths
- bundle validation can catch duplicate normalized targets
- `--bundle-check-only` lets teams export validation and plan reports without touching the workspace

## 7. Incident response handoff kits

Typical need:

- draft a runbook during a live incident
- prepare a status-page update
- generate an escalation-contact file for responders

Why Moon Mustache helps:

- one shared context can feed multiple incident artifacts
- profile-aware manifests can separate degraded and critical severity templates
- bundle validation makes the generated incident pack auditable before writing files

## 8. Developer release packs

Typical need:

- generate a GitHub release body
- produce install / upgrade snippets
- summarize migration notes for downstream developers

Why Moon Mustache helps:

- repeated release fragments can stay in partials
- stable and preview channels can share one manifest while varying install tags
- the same render core works for Markdown, plain text, and developer-facing snippets
