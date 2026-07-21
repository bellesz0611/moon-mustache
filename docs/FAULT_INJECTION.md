# Controlled Fault Injection

Moon Mustache complements coverage and passing-case counts with a controlled fault-injection check. The check makes one temporary source mutation at a time and requires a focused regression test to fail for the intended behavioral reason.

The repository itself is never edited by the runner. Tracked files are copied to a temporary project, each mutation is applied and reverted there, and a machine-readable result can be uploaded with other CI evidence.

## Faults exercised

| Controlled fault | Risk represented | Expected detector |
| --- | --- | --- |
| Disable repeated ampersand escaping | Unsafe or reference-incompatible HTML | HTML escaping regression test |
| Treat `true` as falsey | Reversed Section behavior | Truthy Section regression test |
| Allow `..` output segments | Generated files escaping their destination | Bundle path normalization test |
| Disable the Partial depth guard | Unbounded recursive Partial expansion | Partial-depth resource-limit test |
| Disable parent-context fallback | Nested Sections losing parent values | Parent-scope lookup test |

Run all five controlled faults:

```bash
python scripts/run_fault_injection.py
```

Write the same evidence as JSON:

```bash
python scripts/run_fault_injection.py --json-output _artifacts/fault-injection.json
```

The command succeeds only when every mutant is killed by an actual test failure. Compilation errors, stale mutation anchors, timeouts, and surviving faults do not count as successful detection. This is a deliberately small, reviewable fault set rather than a claim of exhaustive mutation coverage.
