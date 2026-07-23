# Known Limitations

This page records current project boundaries so adopters and reviewers understand what is intentionally not promised yet.

## 1. Pre-`1.0` API stage

The package is public and usable, but still pre-`1.0`.

Core rendering APIs are more stable than helper/reporting surfaces, but some refinements are still possible before a `1.0` boundary is declared.

## 2. File-backed workflows are still target-shaped

The library core is validated on `wasm-gc` and `js`, but the file-oriented CLI flows currently rely on the `js` target through the Node bridge.

That is acceptable for the current project scope, but it is still a meaningful boundary to document.

## 3. Benchmark history is still shallow

The repository now includes benchmark entrypoints and a benchmark snapshot, but not yet a longer release-over-release history with trend visualization.

## 4. External adoption evidence is still emerging

The repository includes multiple consumer-style demos and a separately installable consumer proof, but broad third-party adoption naturally takes longer than the competition development window.

This is good reuse evidence, but it is not the same thing as multiple independently maintained external repositories.

## 5. Scope is intentionally narrow

Moon Mustache does not try to become:

- a logic-heavy template language
- a general text-processing framework
- a full static-site generator

That narrower boundary is intentional, but it also means some users will still need higher-level tooling on top.

## 6. Upstream fixture regeneration remains deliberate

All current core and optional `mustache/spec` fixtures are imported and validated. A scheduled workflow now detects newer commits that touch `specs/` and publishes a machine-readable report; regeneration remains a maintainer-triggered review step so upstream changes are not imported blindly.

## 7. JSON cannot represent executable lambdas

Interpolation and section lambdas are supported for native MoonBit `Value` contexts. They are intentionally unavailable through JSON-only inputs because JSON has no executable function type.

## 8. Community signals are smaller than long-running flagship projects

The repository has grown quickly and now has strong engineering surfaces, but community size, stars, forks, and long-duration maintenance history are naturally still smaller than the biggest reference projects.
