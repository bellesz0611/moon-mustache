from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
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
    "browser_bridge",
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


def source_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines()


def effective_line_count(lines: list[str]) -> int:
    return sum(1 for line in lines if line.strip() and not line.lstrip().startswith("//"))


def collect_loc() -> tuple[int, int, int, int]:
    physical = 0
    effective = 0
    handwritten_effective = 0
    imported_effective = 0
    for dirname in COUNT_DIRS:
        for path in (ROOT / dirname).rglob("*"):
            if not path.is_file() or path.suffix != ".mbt":
                continue
            lines = source_lines(path)
            line_count = effective_line_count(lines)
            physical += len(lines)
            effective += line_count
            if path.name == "official_spec_fixtures.mbt":
                imported_effective += line_count
            else:
                handwritten_effective += line_count
    return physical, effective, handwritten_effective, imported_effective


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


def parse_official_spec_summary(output: str) -> tuple[int, int, int]:
    total = re.search(r"- total cases:\s*(\d+)", output)
    failures = re.search(r"- total failures:\s*(\d+)", output)
    skips = re.search(r"- total skips:\s*(\d+)", output)
    if not total or not failures or not skips:
        raise RuntimeError("Unable to parse official spec report")
    return int(total.group(1)), int(failures.group(1)), int(skips.group(1))


def parse_core_coverage(output: str) -> tuple[int, int, float]:
    covered = 0
    total = 0
    for line in output.splitlines():
        match = re.match(r"^src[\\/].*:\s*(\d+)/(\d+)\s*$", line.strip())
        if match:
            covered += int(match.group(1))
            total += int(match.group(2))
    if total == 0:
        raise RuntimeError("Unable to parse core coverage summary")
    return covered, total, covered * 100.0 / total


def main() -> int:
    physical_loc, effective_loc, handwritten_effective_loc, imported_effective_loc = collect_loc()
    commit_count = int(run(["git", "rev-list", "--count", "HEAD"]))
    head_sha = run(["git", "rev-parse", "--short", "HEAD"])
    moon = moon_cmd()
    moon_version = " | ".join(
        line.strip() for line in run([moon, "version", "--all"]).splitlines() if line.strip()
    )
    moon_test_output = run([moon, "test", "--deny-warn", "--target", "wasm-gc"])
    test_total, test_passed = parse_test_summary(moon_test_output)
    official_output = run([moon, "run", "--target", "wasm-gc", "official_spec_report"])
    official_total, official_failures, official_skips = parse_official_spec_summary(official_output)
    run([moon, "coverage", "clean"])
    run([moon, "test", "--enable-coverage", "--target", "wasm-gc"])
    coverage_output = run([moon, "coverage", "report", "-f", "summary"])
    coverage_covered, coverage_total, coverage_percent = parse_core_coverage(coverage_output)
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

- generated at: `{datetime.now(timezone.utc).isoformat(timespec="seconds")}`
- generated at commit: `{head_sha}`
- public commit count: `{commit_count}`
- MoonBit package: `{PACKAGE_NAME}`
- MoonBit toolchain used for the local verification snapshot: `{moon_version}`

## Code scale

- physical MoonBit source lines across library, CLI, demos, reports, benchmarks, consumer proofs, and bridges: `{physical_loc}`
- effective MoonBit source lines after excluding blank and comment-only lines: `{effective_loc}`
- handwritten effective MoonBit lines: `{handwritten_effective_loc}`
- imported generated official-fixture effective lines, disclosed separately: `{imported_effective_loc}`

## Verification snapshot

- automated tests passing: `{test_passed} / {test_total}`
- imported official fixture cases: `{official_total - official_failures} / {official_total}` passing, `{official_skips}` skipped
- core library coverage: `{coverage_covered} / {coverage_total}` (`{coverage_percent:.1f}%`)
- coverage policy: at least `80.0%`, enforced in CI with summary and Cobertura artifacts
- local verification command: `moon test --deny-warn --target wasm-gc`
- deterministic differential policy: `2048` generated cases with fixed seed `20260710` against `mustache.js`
- latest GitHub library workflow conclusion: {workflow_summary}
- latest GitHub library workflow URL: <{workflow_url}>

## Publication snapshot

- mooncakes latest version: `{mooncakes_version}`
- mooncakes build status: `{mooncakes_build_status}`
- mooncakes download count reported by API: `{mooncakes_downloads}`
- mooncakes docs page: <{mooncakes_docs_url}>

## Notes

- Effective LOC excludes blank and comment-only lines. Imported generated fixture code is never presented as handwritten implementation.
- This snapshot is intentionally narrower than the whole repository filesystem. It focuses on MoonBit implementation and proof surfaces used in competition-facing materials.
- If outward-facing docs mention counts, this file should be treated as the source of truth.
- The repository's public commit count can advance after documentation-only sync commits; regenerate this file whenever you need a fresher exact number.
"""
    DOC_PATH.write_text(content, encoding="utf-8")
    print(f"Wrote {DOC_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
