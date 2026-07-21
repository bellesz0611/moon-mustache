# Metrics Snapshot

This file is the canonical generated metrics snapshot for Moon Mustache. Regenerate it with:

```bash
python scripts/generate_metrics_snapshot.py
```

## Repository state

- generated at: `2026-07-21T09:33:45+00:00`
- generated at commit: `6a82c6a`
- working tree: `dirty (includes uncommitted changes)`
- public commit count: `60`
- MoonBit package: `bellesz0611/moon-mustache`
- MoonBit toolchain used for the local verification snapshot: `moon 0.1.20260703 (6fbf8c3 2026-07-03) ~\moon-toolchain\bin\moon.exe | moonc v0.10.3+16975d007 (2026-07-03) ~\moon-toolchain\bin\moonc.exe | moonrun 0.1.20260703 (6fbf8c3 2026-07-03) ~\moon-toolchain\bin\moonrun.exe | Feature flags enabled: rr_moon_mod,rr_moon_pkg`

## Code scale

- physical MoonBit source lines across library, CLI, demos, reports, benchmarks, consumer proofs, and bridges: `11458`
- effective MoonBit source lines after excluding blank and comment-only lines: `10461`
- handwritten effective MoonBit lines: `8312`
- imported generated official-fixture effective lines, disclosed separately: `2149`

## Verification snapshot

- automated tests passing: `100 / 100`
- imported official fixture cases: `194 / 194` passing, `0` skipped
- core library coverage: `1889 / 2131` (`88.6%`)
- coverage policy: at least `88.0%`, enforced in CI with summary and Cobertura artifacts
- repository-wide instrumented lines: `1889 / 3134` (`60.3%`, informational; CLI, bridges, and demos are verified by integration/smoke jobs rather than this unit-coverage gate)
- CLI black-box integration: `5 / 5` passing
- local verification command: `moon test --deny-warn --target wasm-gc`
- deterministic differential policy: `2048` generated cases across four fixed seeds (`20260710` through `20260713`) against `mustache.js`
- latest GitHub library workflow conclusion: `success` for commit `6a82c6a`
- latest GitHub library workflow URL: <https://github.com/bellesz0611/moon-mustache/actions/runs/29196857820>

## Publication snapshot

- mooncakes latest version: `0.2.0`
- mooncakes build status: `success`
- mooncakes download count reported by API: `13`
- mooncakes docs page: <https://mooncakes.io/docs/bellesz0611/moon-mustache%400.2.0>

## Notes

- Effective LOC excludes blank and comment-only lines. Imported generated fixture code is never presented as handwritten implementation.
- This snapshot is intentionally narrower than the whole repository filesystem. It focuses on MoonBit implementation and proof surfaces used in competition-facing materials.
- If outward-facing docs mention counts, this file should be treated as the source of truth.
- The repository's public commit count can advance after documentation-only sync commits; regenerate this file whenever you need a fresher exact number.
- The adjacent `METRICS_SNAPSHOT.json` contains the same local evidence in a machine-readable form.
