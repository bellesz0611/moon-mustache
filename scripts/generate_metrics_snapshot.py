from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "docs" / "METRICS_SNAPSHOT.md"
PACKAGE_NAME = "bellesz0611/moon-mustache"
GITHUB_REPO = "bellesz0611/moon-mustache"
MOON_MOD_PATH = ROOT / "moon.mod"

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
    "incident_response_demo",
    "developer_release_demo",
    "companion_repo_blueprint",
]


def moon_cmd() -> str:
    for candidate in ("moon.cmd", "moon.exe", "moon"):
        found = shutil.which(candidate)
        if found:
            return found
    return str(Path.home() / ".moon" / "bin" / "moon.exe")


def run(cmd: list[str]) -> str:
    completed = subprocess.run(
        cmd,
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


def try_run(cmd: list[str]) -> str | None:
    completed = subprocess.run(
        cmd,
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        return None
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
    try:
        with urlopen(req, timeout=30) as resp:
            return json.load(resp)
    except (HTTPError, URLError, TimeoutError):
        curl = shutil.which("curl") or shutil.which("curl.exe")
        if curl:
            output = try_run([curl, "-fsSL", url])
            if output:
                return json.loads(output)
        raise


def fetch_text(url: str) -> str:
    req = Request(url, headers={"User-Agent": "moon-mustache-metrics"})
    try:
        with urlopen(req, timeout=30) as resp:
            return resp.read().decode("utf-8", errors="replace")
    except (HTTPError, URLError, TimeoutError):
        curl = shutil.which("curl") or shutil.which("curl.exe")
        if curl:
            output = try_run([curl, "-fsSL", url])
            if output is not None:
                return output
        raise


def package_version() -> str:
    content = MOON_MOD_PATH.read_text(encoding="utf-8")
    match = re.search(r'version\s*=\s*"([^"]+)"', content)
    if not match:
        raise RuntimeError("Unable to parse package version from moon.mod")
    return match.group(1)


def latest_workflow_status() -> tuple[str, str, str]:
    actions_url = f"https://github.com/{GITHUB_REPO}/actions/workflows/ci.yml"
    try:
        payload = fetch_json(
            f"https://api.github.com/repos/{GITHUB_REPO}/actions/workflows/ci.yml/runs?per_page=1"
        )
        runs = payload.get("workflow_runs", [])
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


def mooncakes_status() -> tuple[str, str, int, str]:
    version = package_version()
    docs_url = f"https://mooncakes.io/docs/{PACKAGE_NAME}%40{version}"
    try:
        payload = fetch_json(f"https://mooncakes.io/api/v0/manifest/{PACKAGE_NAME}")
        return (
            payload.get("build_status", "unknown"),
            payload.get("latest_version", "unknown"),
            int(payload.get("downloads", 0)),
            docs_url,
        )
    except (HTTPError, URLError, TimeoutError):
        try:
            fetch_text(docs_url)
            return "docs reachable (api unavailable)", version, 0, docs_url
        except (HTTPError, URLError, TimeoutError):
            return "unknown", version, 0, docs_url


def parse_test_summary(output: str) -> tuple[int, int]:
    match = re.search(r"Total tests:\s*(\d+),\s*passed:\s*(\d+),\s*failed:\s*(\d+)", output)
    if not match:
        raise RuntimeError("Unable to parse moon test summary")
    return int(match.group(1)), int(match.group(2))


def main() -> int:
    total_loc, handwritten_loc, imported_loc = collect_loc()
    commit_count = int(run(["git", "rev-list", "--count", "HEAD"]))
    head_sha = run(["git", "rev-parse", "--short", "HEAD"])
    moon = moon_cmd()
    moon_version = " | ".join(
        line.strip() for line in run([moon, "version"]).splitlines() if line.strip()
    )
    moon_test_output = run([moon, "test", "--deny-warn"])
    test_total, test_passed = parse_test_summary(moon_test_output)
    workflow_conclusion, workflow_sha, workflow_url = latest_workflow_status()
    mooncakes_build_status, mooncakes_version, mooncakes_downloads, mooncakes_docs_url = mooncakes_status()

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
- mooncakes docs page: <{mooncakes_docs_url}>

## Notes

- This snapshot is intentionally narrower than the whole repository filesystem. It focuses on the MoonBit implementation and proof surfaces used in competition-facing materials.
- If outward-facing docs mention counts, this file should be treated as the source of truth.
- The repository's public commit count can advance after documentation-only sync commits; regenerate this file whenever you need a fresher exact number.
"""
    DOC_PATH.write_text(content, encoding="utf-8")
    print(f"Wrote {DOC_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
