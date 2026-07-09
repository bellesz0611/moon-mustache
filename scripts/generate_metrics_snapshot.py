from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "docs" / "METRICS_SNAPSHOT.md"
PACKAGE_NAME = "bellesz0611/moon-mustache"
GITHUB_REPO = "bellesz0611/moon-mustache"

COUNT_DIRS = [
    "src",
    "cli",
    "benchmarks",
    "showcase",
    "scaffold_demo",
    "scenario_report",
    "spec_report",
    "official_spec_report",
    "downstream_consumer",
    "playground_bridge",
    "adoption_demo",
    "content_pipeline_demo",
    "starter_repo_demo",
    "companion_repo_blueprint",
]


def run(cmd: list[str]) -> str:
    completed = subprocess.run(
        cmd,
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


def count_lines(path: Path) -> int:
    return sum(1 for _ in path.open("r", encoding="utf-8"))


def collect_loc() -> tuple[int, int, int]:
    total = 0
    handwritten = 0
    imported = 0
    for dirname in COUNT_DIRS:
        for path in (ROOT / dirname).rglob("*"):
            if not path.is_file():
                continue
            if path.suffix not in {".mbt", ".mbti"}:
                continue
            lines = count_lines(path)
            total += lines
            if path.name == "official_spec_fixtures.mbt":
                imported += lines
            else:
                handwritten += lines
    return total, handwritten, imported


def fetch_json(url: str) -> dict:
    req = Request(url, headers={"User-Agent": "moon-mustache-metrics"})
    with urlopen(req, timeout=30) as resp:
        return json.load(resp)


def fetch_text(url: str) -> str:
    req = Request(url, headers={"User-Agent": "moon-mustache-metrics"})
    with urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8", errors="replace")


def latest_workflow_status() -> tuple[str, str, str]:
    actions_url = f"https://github.com/{GITHUB_REPO}/actions/workflows/ci.yml"
    try:
        payload = fetch_json(
            f"https://api.github.com/repos/{GITHUB_REPO}/actions/runs?per_page=10"
        )
        runs = payload.get("workflow_runs", [])
        for run_info in runs:
            if run_info.get("name") == "check":
                return (
                    run_info.get("conclusion", "unknown"),
                    run_info.get("head_sha", "")[:7],
                    run_info.get("html_url", actions_url),
                )
        if runs:
            run_info = runs[0]
            return (
                run_info.get("conclusion", "unknown"),
                run_info.get("head_sha", "")[:7],
                run_info.get("html_url", actions_url),
            )
    except (HTTPError, URLError, TimeoutError):
        pass

    try:
        badge = fetch_text(
            f"https://github.com/{GITHUB_REPO}/actions/workflows/ci.yml/badge.svg?branch=main"
        ).lower()
        if "passing" in badge or ">pass<" in badge or "success" in badge:
            return "success (badge fallback)", "", actions_url
        if "failing" in badge or "failure" in badge:
            return "failure (badge fallback)", "", actions_url
    except (HTTPError, URLError, TimeoutError):
        pass

    return "unknown", "", actions_url


def mooncakes_status() -> tuple[str, str, int]:
    try:
        payload = fetch_json(f"https://mooncakes.io/api/v0/manifest/{PACKAGE_NAME}")
        return (
            payload.get("build_status", "unknown"),
            payload.get("latest_version", "unknown"),
            int(payload.get("downloads", 0)),
        )
    except (HTTPError, URLError, TimeoutError):
        return "unknown", "unknown", 0


def parse_test_summary(output: str) -> tuple[int, int]:
    match = re.search(r"Total tests:\s*(\d+),\s*passed:\s*(\d+),\s*failed:\s*(\d+)", output)
    if not match:
        raise RuntimeError("Unable to parse moon test summary")
    return int(match.group(1)), int(match.group(2))


def main() -> int:
    total_loc, handwritten_loc, imported_loc = collect_loc()
    commit_count = int(run(["git", "rev-list", "--count", "HEAD"]))
    head_sha = run(["git", "rev-parse", "--short", "HEAD"])
    moon_version = " | ".join(
        line.strip()
        for line in run([str(Path.home() / ".moon" / "bin" / "moon.exe"), "version"]).splitlines()
        if line.strip()
    )
    moon_test_output = run(
        [str(Path.home() / ".moon" / "bin" / "moon.exe"), "test", "--deny-warn"]
    )
    test_total, test_passed = parse_test_summary(moon_test_output)
    workflow_conclusion, workflow_sha, workflow_url = latest_workflow_status()
    mooncakes_build_status, mooncakes_version, mooncakes_downloads = mooncakes_status()

    workflow_summary = f"`{workflow_conclusion}`"
    if workflow_sha:
        workflow_summary += f" for commit `{workflow_sha}`"

    content = f"""# Metrics Snapshot

This file is the canonical generated metrics snapshot for Moon Mustache. Regenerate it with:

```bash
python scripts/generate_metrics_snapshot.py
```

## Repository state

- generated at commit: `{head_sha}`
- public commit count: `{commit_count}`
- MoonBit package: `{PACKAGE_NAME}`
- MoonBit toolchain used for the local verification snapshot: `{moon_version}`

## Code scale

- total MoonBit LOC across library, CLI, demos, reports, benchmarks, consumer demos, bridge code, and companion blueprint proof: `{total_loc}`
- handwritten MoonBit LOC in those surfaces: `{handwritten_loc}`
- imported generated fixture asset LOC: `{imported_loc}`

## Verification snapshot

- automated tests passing: `{test_passed} / {test_total}`
- local verification command: `moon test --deny-warn`
- latest GitHub library workflow conclusion: {workflow_summary}
- latest GitHub library workflow URL: <{workflow_url}>

## Publication snapshot

- mooncakes latest version: `{mooncakes_version}`
- mooncakes build status: `{mooncakes_build_status}`
- mooncakes download count reported by API: `{mooncakes_downloads}`
- mooncakes package page: <https://mooncakes.io/package/{PACKAGE_NAME}>

## Notes

- This snapshot is intentionally narrower than the whole repository filesystem. It focuses on the MoonBit implementation and proof surfaces used in competition-facing materials.
- If outward-facing docs mention counts, this file should be treated as the source of truth.
"""
    DOC_PATH.write_text(content, encoding="utf-8")
    print(f"Wrote {DOC_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
