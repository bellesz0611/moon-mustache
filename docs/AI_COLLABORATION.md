# AI Collaboration Practice

Moon Mustache treats AI assistance as an engineering input, not as proof by itself. The auditable unit is the resulting issue, test, patch, review decision, and CI evidence.

## Workflow

```text
problem or issue
      ↓
agent proposes scope and assumptions
      ↓
failing test or measurable acceptance condition
      ↓
small implementation patch
      ↓
focused checks → full verification artifacts
      ↓
human diff review and commit decision
```

The repository-level instructions in [`AGENTS.md`](../AGENTS.md) define boundaries that apply to coding agents and humans using them.

## Real case: CLI failure exit codes

During black-box verification, strict rendering correctly blocked output for a missing variable but returned process exit code `0`. A missing template file behaved the same way. This meant a shell or CI job could report success even though no valid output was produced.

The correction followed an evidence-first sequence:

1. reproduce the behavior by launching the real JS-target CLI as a child process;
2. define the contract: strict failures and invalid file inputs must return non-zero;
3. update CLI failure branches without changing successful rendering output;
4. add black-box assertions for stdout, exit code, lint diagnostics, file IO, and Bundle artifacts;
5. run the MoonBit matrix, CLI integration suite, differential suite, coverage gate, and Playground build;
6. leave the final commit and push decision to the repository owner.

The regression suite is [`scripts/test_cli_integration.py`](../scripts/test_cli_integration.py). Its JSON and JUnit outputs are uploaded by the JS CI lane.

## Real case: coverage accounting

Coverage work uncovered a tool-specific reporting edge: MoonBit summary output omits rows for files that reach 100% while retaining them in the repository total. Summing only visible `src/` rows therefore produced an inconsistent denominator.

The repository now subtracts explicit non-core rows from the repository total, preserving fully covered core files. [`scripts/run_coverage.py`](../scripts/run_coverage.py) emits human-readable summary, Cobertura XML, and JSON from the same run. The decision is guarded by an enforced threshold instead of a screenshot or manually copied percentage.

## Human review checklist

For meaningful AI-assisted changes, review should answer:

- Is the requested scope preserved, without unrelated features?
- Did a test fail before the fix or otherwise express a measurable contract?
- Are imported fixtures, generated cases, and handwritten tests counted separately?
- Are failure paths and exit codes checked, not only happy-path output?
- Are metrics generated from the current worktree and clearly marked dirty when uncommitted?
- Did a human inspect the diff and decide whether to commit and push?

The pull request template carries these checks into normal repository maintenance.

## Evidence boundaries

- This document does not claim autonomous approval or independent adoption.
- It does not reconstruct private prompt transcripts.
- Passing tests demonstrates conformance to encoded checks, not correctness outside the tested scope.
- A fixed differential seed set is reproducible but not exhaustive.
- AI assistance is disclosed when material; authorship and maintenance responsibility remain human-owned.
