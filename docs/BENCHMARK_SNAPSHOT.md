# Benchmark Snapshot

This page records one repository-local benchmark snapshot so reviewers and future contributors can see a concrete baseline rather than only a benchmark entrypoint.

## Environment note

The following results were captured on the maintainer machine on `2026-07-08` using:

- current repository state at the time of capture
- `moon run benchmarks`
- local machine timings only

These values are useful for regression tracking inside the project, not for universal cross-machine comparison.

## Snapshot

| Workload | Mean | Median | Runs | Batch Size |
| --- | ---: | ---: | ---: | ---: |
| `plain_render` | `0.7882100050` | `0.7635460000` | `10` | `100000` |
| `section_render` | `2.6859206600` | `2.6278902172` | `10` | `29695` |
| `partial_render` | `3.3048493345` | `3.2523716508` | `10` | `28925` |
| `prepared_partial_render` | `1.5300593877` | `1.5283853027` | `10` | `61671` |
| `json_bundle_render` | `4.8422745870` | `4.7944233074` | `10` | `19187` |

## Interpretation

- `plain_render` gives the simplest baseline for escaped interpolation
- `section_render` reflects looping and repeated context lookup
- `partial_render` captures fragment reuse overhead
- `prepared_partial_render` measures the compile-once/render-many path and shows the benefit of prepared APIs under repeated partial expansion
- `json_bundle_render` covers a heavier integration path closer to real workflow use

On the current maintainer machine, `prepared_partial_render` is about `2.16x` faster than the regular `partial_render` path in this benchmark.

## Why this page exists

The repository already includes a benchmark entrypoint, but publishing a concrete snapshot improves:

- release-to-release comparison
- evaluator confidence that the benchmark path is real
- future optimization discussions
