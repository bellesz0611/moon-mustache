# Benchmark Notes

Moon Mustache ships a benchmark entrypoint so performance work is visible and reproducible, not just claimed.

## Run

```bash
moon run --target wasm-gc benchmarks
```

## What is currently measured

- plain render
- section-heavy render
- partial-heavy render
- JSON bundle render

These workloads are intended to cover the major execution paths a reusable template engine hits in practice.

## How to read the output

- compare workloads against each other on the same machine first
- use repeated runs to watch for regressions after parser or renderer changes
- do not compare raw numbers across different operating systems, MoonBit versions, or hardware without noting the environment

## What the benchmark data is good for

- spotting obvious regressions
- understanding whether sections or partials dominate runtime
- checking whether new diagnostics or validation features changed the hot path too much

## What it does not yet claim

- cross-language leaderboard results
- universal absolute performance guarantees
- memory profiling or allocation profiling

## Next benchmark improvements

- fixed-size benchmark profiles with documented template/context shapes
- before/after comparisons for major optimization work
- published benchmark snapshots in release notes
