# Spec coverage snapshot

This document records the current implementation status of the Moon Mustache core.

## Supported today

- plain text segments
- escaped variables: `{{name}}`
- unescaped variables: `{{{name}}}`, `{{& name}}`
- sections: `{{#name}}...{{/name}}`
- inverted sections: `{{^name}}...{{/name}}`
- comments: `{{! comment }}`
- partials: `{{> partial }}`
- delimiter changes: `{{=<% %>=}}`
- standalone section/comment/partial/set-delimiter lines
- dotted lookup: `{{user.name}}`
- current-context lookup: `{{.}}`
- array iteration in sections
- parent-scope lookup from nested section contexts
- JSON context conversion helpers
- checked rendering APIs with diagnostics
- strict checked rendering with missing-variable tracking
- dotted path context builders and recursive object merge helpers
- multi-file bundle rendering APIs
- manifest profile parsing and bundle render reports
- bundle validation, normalized path checks, and generation plans
- scenario report coverage for real-world workflows
- imported official `mustache/spec` fixture coverage and reporting
- CLI file-backed template / context / partial loading on `js` target
- spec-style fixture coverage for interpolation, comments, sections, inverted sections, partials, delimiters, standalone lines, whitespace, and diagnostics

## Not implemented yet

- target-agnostic library-level file loading
- fully automated upstream fixture synchronization in CI
- richer end-user parse diagnostics categorization
- compatibility report against multiple upstream implementations

## Notes

- Missing variables render as empty output.
- Plain `render(...)` stays permissive for embedding convenience.
- `render_checked(...)` and `render_with_partials_checked(...)` expose parse and partial diagnostics.
- `RenderOptions::strict()` can additionally collect missing variable names.
- Missing partials are reported through checked rendering APIs.
- Partial expansion is guarded by a depth limit to avoid unbounded recursion.
- `moon run spec_report` prints a Markdown summary for the current spec-style suite.
- `moon run official_spec_report` prints a Markdown summary for imported upstream fixtures.
