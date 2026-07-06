# Third-Party Notices

Moon Mustache includes imported compatibility fixtures from upstream open-source projects.

## mustache/spec

- project: `mustache/spec`
- source: <https://github.com/mustache/spec>
- local path: `third_party/mustache-spec/specs`
- files used:
  - `comments.json`
  - `delimiters.json`
  - `interpolation.json`
  - `inverted.json`
  - `partials.json`
  - `sections.json`
- usage in this repository:
  - source fixture data for compatibility verification
  - generated into `src/official_spec_fixtures.mbt` through `scripts/generate_official_spec_fixtures.py`
- upstream license: MIT License

The upstream license text is preserved in `third_party/mustache-spec/LICENSE`.
