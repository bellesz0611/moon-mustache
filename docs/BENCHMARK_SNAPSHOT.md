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
| `plain_render` | `0.7229649950` | `0.7062770000` | `10` | `100000` |
| `section_render` | `2.3239005689` | `2.3280004841` | `10` | `41310` |
| `partial_render` | `5.2394348367` | `5.2804038107` | `10` | `23303` |
| `json_bundle_render` | `6.2823793469` | `6.2004981680` | `10` | `15557` |

## Interpretation

- `plain_render` gives the simplest baseline for escaped interpolation
- `section_render` reflects looping and repeated context lookup
- `partial_render` captures fragment reuse overhead
- `json_bundle_render` covers a heavier integration path closer to real workflow use

## Why this page exists

The repository already includes a benchmark entrypoint, but publishing a concrete snapshot improves:

- release-to-release comparison
- evaluator confidence that the benchmark path is real
- future optimization discussions
