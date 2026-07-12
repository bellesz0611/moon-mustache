# Metrics Snapshot

This file is the canonical generated metrics snapshot for Moon Mustache. Regenerate it with:

```bash
python scripts/generate_metrics_snapshot.py
```

## Repository state

- generated at: `2026-07-12T14:40:56+00:00`
- generated at commit: `8624958`
- public commit count: `59`
- MoonBit package: `bellesz0611/moon-mustache`
- MoonBit toolchain used for the local verification snapshot: `moon 0.1.20260703 (6fbf8c3 2026-07-03) ~\moon-toolchain\bin\moon.exe | moonc v0.10.3+16975d007 (2026-07-03) ~\moon-toolchain\bin\moonc.exe | moonrun 0.1.20260703 (6fbf8c3 2026-07-03) ~\moon-toolchain\bin\moonrun.exe | Feature flags enabled: rr_moon_mod,rr_moon_pkg`

## Code scale

- physical MoonBit source lines across library, CLI, demos, reports, benchmarks, consumer proofs, and bridges: `11147`
- effective MoonBit source lines after excluding blank and comment-only lines: `10181`
- handwritten effective MoonBit lines: `8032`
- imported generated official-fixture effective lines, disclosed separately: `2149`

## Verification snapshot

- automated tests passing: `85 / 85`
- imported official fixture cases: `194 / 194` passing, `0` skipped
- core library coverage: `1653 / 2028` (`81.5%`)
- coverage policy: at least `80.0%`, enforced in CI with summary and Cobertura artifacts
- local verification command: `moon test --deny-warn --target wasm-gc`
- deterministic differential policy: `2048` generated cases with fixed seed `20260710` against `mustache.js`
- latest GitHub library workflow conclusion: `success` for commit `8624958`
- latest GitHub library workflow URL: <https://github.com/bellesz0611/moon-mustache/actions/runs/29196325065>

## Publication snapshot

- mooncakes latest version: `0.2.0`
- mooncakes build status: `success`
- mooncakes download count reported by API: `6`
- mooncakes docs page: <https://mooncakes.io/docs/bellesz0611/moon-mustache%400.2.0>

## Notes

- Effective LOC excludes blank and comment-only lines. Imported generated fixture code is never presented as handwritten implementation.
- This snapshot is intentionally narrower than the whole repository filesystem. It focuses on MoonBit implementation and proof surfaces used in competition-facing materials.
- If outward-facing docs mention counts, this file should be treated as the source of truth.
- The repository's public commit count can advance after documentation-only sync commits; regenerate this file whenever you need a fresher exact number.
