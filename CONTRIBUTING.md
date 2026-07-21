# Contributing

Thanks for helping improve Moon Mustache.

This repository is no longer in a bootstrap-only phase. Contributions should now preserve compatibility evidence, keep behavior understandable, and improve the project as a reusable MoonBit dependency.

## What kinds of contributions are welcome

- parser, renderer, and diagnostics improvements
- spec-compatibility expansion
- CLI and bundle workflow improvements
- benchmark and regression-test additions
- documentation, examples, and evaluator-facing polish
- downstream integration examples for real MoonBit usage

## Ground rules

- keep one meaningful change per commit when practical
- update tests when behavior changes
- update docs, examples, or reports when user-facing behavior changes
- avoid adding features that turn Mustache into a logic-heavy custom template language
- prefer compatibility and reuse over clever syntax extensions

## Local verification

Before opening a pull request, run the most relevant checks for your change:

```bash
python scripts/verify.py
```

This runs documentation validation, formatting, `wasm-gc` check/test, official fixture reporting, and CLI black-box integration with per-step logs.

If you touched the CLI, bundle rendering, spec coverage, or the browser demo, also verify the related flows:

```bash
moon run showcase
moon run official_spec_report
moon run --target js cli --template-file examples/files/template.mustache --json-file examples/files/context.json --partials-json-file examples/files/partials.json
cd playground
npm run build
npm run smoke
```

For release-oriented or cross-backend changes, run `python scripts/verify.py --profile full`. AI-assisted contributions follow the disclosure and human-review policy in [docs/AI_COLLABORATION.md](docs/AI_COLLABORATION.md).

## Review priorities

Reviews focus on:

- Mustache semantics staying predictable
- compatibility evidence staying reproducible
- diagnostics staying clear
- public API changes being intentional
- CI and release-readiness impacts being documented

## Good first contribution areas

- add focused compatibility cases
- improve CLI help text or examples
- tighten diagnostics wording
- extend use-case documentation
- improve benchmark notes or downstream consumer examples
