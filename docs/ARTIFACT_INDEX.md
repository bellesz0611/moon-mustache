# Artifact Index

This page is the fastest evaluator-facing map of what Moon Mustache produces, where the evidence lives, and how to reproduce it.

## 1. Start here

| Goal | Command or file | What it proves |
| --- | --- | --- |
| Quick project overview | [README.md](../README.md) | Scope, maturity, public links, core capabilities |
| Special-award evidence | [SPECIAL_AWARD_EVIDENCE.md](SPECIAL_AWARD_EVIDENCE.md) | Testing/documentation claims, boundaries, and shortest reproduction path |
| Judge-facing summary | [JUDGE_QUICKLOOK.md](JUDGE_QUICKLOOK.md) | Why the project is not a shell repository |
| Exact current metrics | [METRICS_SNAPSHOT.md](METRICS_SNAPSHOT.md) | Commit count, LOC, test count, workflow state |
| Machine-readable metrics | [METRICS_SNAPSHOT.json](METRICS_SNAPSHOT.json) | Structured form of the generated evidence |
| Final acceptance posture | [FINAL_ACCEPTANCE_REPORT.md](FINAL_ACCEPTANCE_REPORT.md) | Completion against final-stage expectations |

## 2. Fast manual verification

| Command | What it proves |
| --- | --- |
| `python scripts/verify.py` | Acceptance run with per-step logs and JSON summary |
| `python scripts/check_metrics_freshness.py` | Canonical Markdown/JSON agreement and snapshot commit freshness |
| `moon test --deny-warn` | Regression safety and clean diagnostics |
| `python scripts/verify_official_spec_fixtures.py` | Pinned upstream identity, local checksums, case counts, license, and generated-source integrity |
| `python scripts/test_cli_integration.py` | Real CLI output, failure exit codes, file IO, lint, and bundle artifacts |
| `python scripts/run_fault_injection.py` | Five controlled faults must each trigger a focused test failure |
| `moon run showcase` | Realistic library-level render outputs |
| `moon run official_spec_report` | Imported upstream `mustache/spec` compatibility evidence |
| `moon run cli --template "{{#user}}{{name}}{{/user}}{{> footer}}" --scan` | Reference scanning through the CLI |
| `moon run benchmarks` | Measured performance surfaces |
| `cd playground && npm ci && npm run differential` | 2,048 deterministic comparisons against `mustache.js` |

## 3. Reuse demos

| Demo | Command | Scenario |
| --- | --- | --- |
| Downstream consumer | `moon run downstream_consumer` | Separate MoonBit package reusing only the public API |
| Adoption demo | `moon run adoption_demo` | Operations rollout kit with profile-aware bundle rendering |
| Content pipeline demo | `moon run content_pipeline_demo` | Markdown, text, and HTML content outputs |
| Starter repo demo | `moon run starter_repo_demo` | Starter-repository generator |
| Incident response demo | `moon run incident_response_demo` | Incident runbook, status-page, and escalation package |
| Developer release demo | `moon run developer_release_demo` | GitHub release, install guide, and migration pack |

## 4. Benchmark and CI artifacts

| Artifact | Produced by | Notes |
| --- | --- | --- |
| `benchmarks.json` | `check` workflow on the `wasm-gc` lane | Machine-readable benchmark output |
| `benchmarks.md` | `check` workflow on the `wasm-gc` lane | Human-readable benchmark summary |
| `coverage-summary.txt`, `coverage.xml`, and `coverage.json` | `check` workflow on the `wasm-gc` lane | 88% core threshold plus human, standard, and machine-readable evidence |
| `cli-integration.json` | `check` workflow on the `js` lane | Machine-readable black-box CLI result |
| `official-fixture-integrity.json` | `check` workflow on the `wasm-gc` lane | Machine-readable fixture provenance and integrity result |
| `fault-injection.json` | `check` workflow on the `wasm-gc` lane | Killed, survived, and invalid controlled-fault results |
| `differential.json` | `playground` workflow | Four fixed seeds, reference version, duration, and replayable failures |
| `release-readiness-artifacts` | `release-readiness` workflow | Metrics snapshot, reports, demos, and benchmark outputs |
| GitHub Pages artifact | `deploy-playground` workflow | Runnable Vue UI containing the MoonBit-compiled ESM |

## 5. Supporting documents

| File | Purpose |
| --- | --- |
| [COMPATIBILITY.md](COMPATIBILITY.md) | Supported feature matrix |
| [OFFICIAL_SPEC.md](OFFICIAL_SPEC.md) | Imported upstream fixture coverage |
| [DIFFERENTIAL_TESTING.md](DIFFERENTIAL_TESTING.md) | Cross-implementation randomized parity methodology |
| [FAULT_INJECTION.md](FAULT_INJECTION.md) | Controlled fault set, detection policy, and evidence boundaries |
| [../src/README.mbt.md](../src/README.mbt.md) | Executable API examples compiled as tests |
| [AI_COLLABORATION.md](AI_COLLABORATION.md) | Auditable AI workflow, real defect cases, and evidence boundaries |
| [BENCHMARK_SNAPSHOT.md](BENCHMARK_SNAPSHOT.md) | Repository-local benchmark snapshot |
| [ADOPTION_EVIDENCE.md](ADOPTION_EVIDENCE.md) | Why the project is reusable beyond one example |
| [USE_CASES.md](USE_CASES.md) | Concrete workflow categories |

## 6. Public links

- GitHub: <https://github.com/bellesz0611/moon-mustache>
- GitLink: <https://www.gitlink.org.cn/miemie0619/moon-mustache-mbt>
- mooncakes docs: <https://mooncakes.io/docs/bellesz0611/moon-mustache%400.2.0>
- online playground: <https://bellesz0611.github.io/moon-mustache/>
