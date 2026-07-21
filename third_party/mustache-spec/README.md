# Imported Upstream Fixtures

This directory stores selected upstream compatibility fixtures imported from `mustache/spec`.

- upstream repository: <https://github.com/mustache/spec>
- pinned upstream commit: [`e8ec001db7f594521e773c34866aca2b5d6b0037`](https://github.com/mustache/spec/tree/e8ec001db7f594521e773c34866aca2b5d6b0037)
- upstream license: MIT License
- local fixture directory: `specs/`
- local generator consumer: `scripts/generate_official_spec_fixtures.py`
- integrity manifest: `MANIFEST.json`
- offline verifier: `python scripts/verify_official_spec_fixtures.py`

These files are used for compatibility verification and report generation. They are not handwritten Moon Mustache core implementation code. Their JSON values match the pinned upstream commit; local whitespace formatting is protected by UTF-8/LF-normalized SHA-256 values in the manifest so checks are stable on Windows and Unix.
