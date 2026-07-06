# Quick Start

This guide is for users who want to get productive with Moon Mustache fast.

## Path 1: Inline render in 30 seconds

```bash
moon run cli --template "Hello {{name}}" --var name=MoonBit
```

Use this mode when you want to:

- confirm the project is installed correctly
- try a small template by hand
- debug variable lookup without touching files

## Path 2: Render from files

```bash
moon run --target js cli --template-file examples/files/template.mustache --json-file examples/files/context.json --partials-json-file examples/files/partials.json
```

Use this mode when you want to:

- keep templates in version control
- store context as JSON
- test partial composition with realistic inputs

Note:

- file-backed CLI flows currently require the `js` target
- Node.js is needed because the CLI uses a small filesystem bridge in that mode

## Path 3: Validate a bundle manifest

```bash
moon run --target js cli --bundle-manifest-file examples/bundle/manifest.json --bundle-profile dev --json-file examples/bundle/context.json --bundle-check-only --bundle-validation-file out_bundle_check/validation.md --bundle-plan-file out_bundle_check/plan.md
```

Use this mode when you want to:

- validate multiple generated files before writing them
- inspect output paths and missing variables
- integrate generation checks into CI

## Most useful discovery commands

```bash
moon run cli --examples
moon run cli --print-default-template
moon run cli --print-sample-manifest
moon run showcase
moon run scenario_report
moon run official_spec_report
```

## If something goes wrong

The CLI now prints fix-oriented diagnostics. Common cases:

- missing variable: add it with `--var`, `--json`, or `--json-file`
- missing partial: add it with `--partial` or `--partials-json-file`
- JSON parse failure: prefer `--json-base64` on PowerShell when quoting is awkward
- file IO not supported: re-run with `moon run --target js cli ...`
