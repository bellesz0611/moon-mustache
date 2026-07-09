# Benchmark Snapshot

This page records one repository-local benchmark snapshot so reviewers and future contributors can see a concrete baseline rather than only a benchmark entrypoint.

## Environment note

The following results were captured on the maintainer machine on `2026-07-09` using:

- current repository state at the time of capture
- `moon run benchmarks`
- local machine timings only

These values are useful for regression tracking inside the project, not for universal cross-machine comparison.

## Snapshot

| Workload | Mean | Median | Runs | Batch Size |
| --- | ---: | ---: | ---: | ---: |
| `plain_render` | `0.8672734050` | `0.8444680000` | `10` | `100000` |
| `section_render` | `2.3702646279` | `2.3508510588` | `10` | `41889` |
| `partial_render` | `3.0590400856` | `3.0411497474` | `10` | `32468` |
| `prepared_partial_render` | `1.5509021160` | `1.5381218897` | `10` | `74149` |
| `json_bundle_render` | `4.2147034504` | `4.2163642369` | `10` | `25736` |
| `strict_missing_render` | `2.4795168292` | `2.4369761998` | `10` | `38445` |

## Interpretation

- `plain_render` gives the simplest baseline for escaped interpolation
- `section_render` reflects looping and repeated context lookup
- `partial_render` captures fragment reuse overhead
- `prepared_partial_render` measures the compile-once/render-many path and shows the benefit of prepared APIs under repeated partial expansion
- `json_bundle_render` covers a heavier integration path closer to real workflow use
- `strict_missing_render` exercises the diagnostics-heavy path where the same missing variables appear many times and the renderer must deduplicate them efficiently

On the current maintainer machine, `prepared_partial_render` is about `1.97x` faster than the regular `partial_render` path in this benchmark.

The new `strict_missing_render` workload exists to keep the checked-rendering path honest. It makes repeated missing-variable reporting visible in benchmarks so future regressions in diagnostics collection are easier to spot.

## Why this page exists

The repository already includes a benchmark entrypoint, but publishing a concrete snapshot improves:

- release-to-release comparison
- evaluator confidence that the benchmark path is real
- future optimization discussions
