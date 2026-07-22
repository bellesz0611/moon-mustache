# Release Checklist

Run the final public-state gate after pushing both mirrors and waiting for CI:

```bash
python scripts/check_submission_readiness.py --json-output _artifacts/submission-readiness.json
```

This requires a clean local `main`, fresh generated metrics, matching GitHub and GitLink `main` commits, GitHub's default branch set to `main`, successful `check`, `playground`, and `deploy-playground` push runs for the exact local commit, and GitLink's default branch either named `main` or synchronized to the same final commit. Open pull requests are reported for review but do not automatically fail the gate.

The checker uses `GITHUB_TOKEN` or `GH_TOKEN` when available, which avoids the low anonymous GitHub API rate limit during repeated submission audits.

## Before tagging

- `moon check`
- `moon test`
- `moon fmt --check`
- `moon info --target all`
- `moon run --target js cli --template-file ... --json-file ...`
- `moon run scenario_report`
- `moon run official_spec_report`
- `moon run downstream_consumer`
- `moon run --target js cli --bundle-manifest-file ... --bundle-check-only ...`
- `cd playground && npm run build && npm run smoke`
- refresh compatibility notes if behavior changed
- update README examples if CLI flags changed
- update `CHANGELOG.md`
- review [DEPENDENCY_REVIEW.md](DEPENDENCY_REVIEW.md) and rerun `npm audit --audit-level=high`
- confirm `release-readiness` workflow artifacts still make sense

## Before competition submission update

- verify GitHub and GitLink repositories stay in sync
- ensure CI is green on the current branch
- include benchmark output snapshot
- refresh `docs/SPEC_COVERAGE.md`
- refresh `docs/COMPATIBILITY.md`
- refresh `docs/OFFICIAL_SPEC.md`
- refresh `docs/PUBLISHING.md`
- refresh `docs/EVALUATION_SUMMARY.md`

## Before mooncakes.io publishing

- stabilize public API names
- confirm package metadata in `moon.mod`
- document supported targets and current file IO limitations
- prepare semver policy and changelog notes
