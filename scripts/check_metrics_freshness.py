from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
JSON_PATH = ROOT / "docs" / "METRICS_SNAPSHOT.json"
DOC_PATH = ROOT / "docs" / "METRICS_SNAPSHOT.md"


def git(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
    )


def main() -> int:
    payload = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    markdown = DOC_PATH.read_text(encoding="utf-8")
    errors: list[str] = []

    snapshot_commit = payload["repository"]["commit"]
    resolved = git("rev-parse", "--verify", f"{snapshot_commit}^{{commit}}")
    if resolved.returncode != 0:
        errors.append(f"snapshot commit is not available locally: {snapshot_commit}")
    else:
        ancestor = git("merge-base", "--is-ancestor", snapshot_commit, "HEAD")
        if ancestor.returncode != 0:
            errors.append(f"snapshot commit is not an ancestor of HEAD: {snapshot_commit}")
        else:
            distance_result = git("rev-list", "--count", f"{snapshot_commit}..HEAD")
            distance = int(distance_result.stdout.strip())
            if distance > 1:
                errors.append(
                    f"metrics snapshot is {distance} commits behind HEAD; regenerate it after implementation changes"
                )

    if payload["repository"]["working_tree_dirty"]:
        errors.append("committed metrics snapshot was generated from a dirty working tree")

    try:
        verification = payload["verification"]
        expected_lines = [
            (
                "MoonBit test count",
                f"automated tests passing: `{verification['moon_tests']['passed']} / {verification['moon_tests']['total']}`",
            ),
            (
                "CLI integration count",
                f"CLI black-box integration: `{verification['cli_integration']['passed']} / {verification['cli_integration']['total']}` passing",
            ),
            (
                "CLI testable-core coverage",
                "CLI testable-core coverage: "
                f"`{verification['cli_core_coverage']['covered']} / "
                f"{verification['cli_core_coverage']['total']}` "
                f"(`{verification['cli_core_coverage']['percent']:.1f}%`)",
            ),
            (
                "fault-injection count",
                f"controlled fault injection: `{verification['fault_injection']['killed']} / {verification['fault_injection']['total']}` mutants killed",
            ),
            (
                "backend conformance count",
                "local backend golden conformance: "
                f"`{sum(item['status'] == 'passed' for item in verification['backend_conformance']['results'])} / "
                f"{len(verification['backend_conformance']['results'])}` available targets match",
            ),
        ]
    except KeyError as error:
        errors.append(f"metrics snapshot is missing required field: {error}")
        expected_lines = []
    for label, expected in expected_lines:
        if expected not in markdown:
            errors.append(f"Markdown and JSON disagree on {label}")

    if errors:
        print("Metrics freshness validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Metrics freshness passed: snapshot commit {snapshot_commit}, at most one commit behind HEAD")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
