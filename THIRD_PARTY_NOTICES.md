# Third-Party Notices

Moon Mustache includes imported compatibility fixtures from upstream open-source projects.

## mustache/spec

- project: `mustache/spec`
- source: <https://github.com/mustache/spec>
- pinned source commit: [`e8ec001db7f594521e773c34866aca2b5d6b0037`](https://github.com/mustache/spec/tree/e8ec001db7f594521e773c34866aca2b5d6b0037)
- local path: `third_party/mustache-spec/specs`
- files used:
  - `comments.json`
  - `delimiters.json`
  - `interpolation.json`
  - `inverted.json`
  - `partials.json`
  - `sections.json`
  - `~dynamic-names.json`
  - `~inheritance.json`
  - `~lambdas.json`
- usage in this repository:
  - source fixture data for compatibility verification
  - generated into `src/official_spec_fixtures.mbt` through `scripts/generate_official_spec_fixtures.py`
  - integrity recorded in `third_party/mustache-spec/MANIFEST.json` and checked offline in CI
- upstream license: MIT License

The upstream license text is preserved in `third_party/mustache-spec/LICENSE`.
