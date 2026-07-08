# Roadmap

## Current progress

已完成的基础能力：

- repository / module / CI scaffolding
- scanner, parser, context stack, renderer core pipeline
- escaped and unescaped variable rendering
- sections, inverted sections, comments, partials, delimiter changes
- standalone line trimming for section-like tags
- dotted lookup and current-context lookup
- JSON context helpers and checked rendering APIs
- render options with missing-variable diagnostics
- dotted assignment context builder and recursive value merge
- multi-file bundle rendering API
- lightweight CLI demo with diagnostics
- file-backed CLI rendering flow on `js` target
- spec-style suite and Markdown compatibility report
- imported official `mustache/spec` fixture suites and compatibility report
- scenario report and downstream consumer package
- manifest validation and generation-plan reporting
- showcase / scaffold_demo / benchmark entrypoints
- unit tests for main rendering branches
- independent playground smoke workflow
- repository governance, security, support, and contribution templates
- mooncakes.io package publication

## Next milestone

下一阶段重点补齐“版本演进能力”和“生态 adoption 证据”：

- target-agnostic file-based rendering helpers
- automated upstream fixture synchronization workflow
- richer parse/render diagnostics typing
- stronger release artifact snapshots across versions
- more complete end-to-end generated artifact examples
- more external adoption examples and compatibility comparison notes

## Competition-oriented goals

为了更适合作为比赛交付成果，项目会继续加强：

- clearer API stability promises
- larger compatibility case volume across more implementations
- stronger benchmark and regression-test coverage
- compatibility notes against existing Mustache implementations
- packaging and publishing readiness for mooncakes.io

## Longer-term direction

如果项目继续维护，后续还会探索：

- official mustache/spec fixture sync automation
- reusable adapters for file generation and scaffolding tools
- optional higher-level data-loading helpers
- stronger partial recursion policy and debug output
- report export for release gates and ecosystem consumers
