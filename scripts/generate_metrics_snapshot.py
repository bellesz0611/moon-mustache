from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
DOC_PATH = ROOT / "docs" / "METRICS_SNAPSHOT.md"
JSON_PATH = ROOT / "docs" / "METRICS_SNAPSHOT.json"
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
    "backend_conformance",
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
            f"https://api.github.com/repos/{GITHUB_REPO}/actions/workflows/ci.yml/runs?branch=main&event=push&per_page=1"
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
    repository_covered, repository_total, _ = parse_repository_coverage(output)
    non_core_covered = 0
    non_core_total = 0
    for line in output.splitlines():
        match = re.match(r"^(.+\.mbt):\s*(\d+)/(\d+)\s*$", line.strip())
        if match and not match.group(1).replace("\\", "/").startswith("src/"):
            non_core_covered += int(match.group(2))
            non_core_total += int(match.group(3))
    covered = repository_covered - non_core_covered
    total = repository_total - non_core_total
    return covered, total, covered * 100.0 / total


def parse_repository_coverage(output: str) -> tuple[int, int, float]:
    match = re.search(r"^Total:\s*(\d+)/(\d+)\s*$", output, re.MULTILINE)
    if not match:
        raise RuntimeError("Unable to parse repository coverage total")
    covered = int(match.group(1))
    total = int(match.group(2))
    return covered, total, covered * 100.0 / total


def main() -> int:
    generated_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    physical_loc, effective_loc, handwritten_effective_loc, imported_effective_loc = collect_loc()
    commit_count = int(run(["git", "rev-list", "--count", "HEAD"]))
    head_sha = run(["git", "rev-parse", "--short", "HEAD"])
    working_tree_dirty = bool(run(["git", "status", "--short"]))
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
    repository_covered, repository_total, repository_percent = parse_repository_coverage(coverage_output)
    coverage_covered, coverage_total, coverage_percent = parse_core_coverage(coverage_output)
    with tempfile.TemporaryDirectory(prefix="moon-mustache-metrics-") as directory:
        cli_json_path = Path(directory) / "cli-integration.json"
        run([sys.executable, "scripts/test_cli_integration.py", "--json-output", str(cli_json_path)])
        cli_payload = json.loads(cli_json_path.read_text(encoding="utf-8"))
        fault_json_path = Path(directory) / "fault-injection.json"
        run([sys.executable, "scripts/run_fault_injection.py", "--json-output", str(fault_json_path)])
        fault_payload = json.loads(fault_json_path.read_text(encoding="utf-8"))
        backend_json_path = Path(directory) / "backend-conformance.json"
        run(
            [
                sys.executable,
                "scripts/test_backend_conformance.py",
                "--json-output",
                str(backend_json_path),
            ]
        )
        backend_payload = json.loads(backend_json_path.read_text(encoding="utf-8"))
    workflow_conclusion, workflow_sha, workflow_url = latest_workflow_status()
    mooncakes_build_status, mooncakes_version, mooncakes_downloads, mooncakes_docs_url = mooncakes_status()

    workflow_summary = f"`{workflow_conclusion}`"
    if workflow_sha:
        workflow_summary += f" for commit `{workflow_sha}`"

    repository_state = "dirty (includes uncommitted changes)" if working_tree_dirty else "clean"
    content = f"""# Metrics Snapshot

This file is the canonical generated metrics snapshot for Moon Mustache. Regenerate it with:

```bash
python scripts/generate_metrics_snapshot.py
```

## Repository state

- generated at: `{generated_at}`
- generated at commit: `{head_sha}`
- working tree: `{repository_state}`
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
- coverage policy: at least `88.0%`, enforced in CI with summary and Cobertura artifacts
- repository-wide instrumented lines: `{repository_covered} / {repository_total}` (`{repository_percent:.1f}%`, informational; CLI, bridges, and demos are verified by integration/smoke jobs rather than this unit-coverage gate)
- CLI black-box integration: `{cli_payload['passed']} / {cli_payload['total']}` passing
- controlled fault injection: `{fault_payload['killed']} / {fault_payload['total']}` mutants killed, `{fault_payload['survived']}` survived, `{fault_payload['invalid']}` invalid
- local backend golden conformance: `{sum(item['status'] == 'passed' for item in backend_payload['results'])} / {len(backend_payload['results'])}` available targets match, with four targets required in Linux CI
- local verification command: `moon test --deny-warn --target wasm-gc`
- deterministic differential policy: `6144` generated cases across four fixed seeds (`20260710` through `20260713`) against `mustache.js`
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
- The adjacent `METRICS_SNAPSHOT.json` contains the same local evidence in a machine-readable form.
"""
    DOC_PATH.write_text(content, encoding="utf-8")
    machine_payload = {
        "schema_version": 1,
        "generated_at": generated_at,
        "repository": {
            "commit": head_sha,
            "working_tree_dirty": working_tree_dirty,
            "commit_count": commit_count,
        },
        "package": {
            "name": PACKAGE_NAME,
            "version": package_version(),
            "moonbit_toolchain": moon_version,
        },
        "code_scale": {
            "physical_moonbit_lines": physical_loc,
            "effective_moonbit_lines": effective_loc,
            "handwritten_effective_moonbit_lines": handwritten_effective_loc,
            "imported_fixture_effective_lines": imported_effective_loc,
        },
        "verification": {
            "moon_tests": {"passed": test_passed, "total": test_total},
            "official_fixtures": {
                "passed": official_total - official_failures,
                "total": official_total,
                "skipped": official_skips,
            },
            "core_coverage": {
                "covered": coverage_covered,
                "total": coverage_total,
                "percent": round(coverage_percent, 1),
                "gate_percent": 88.0,
            },
            "repository_coverage": {
                "covered": repository_covered,
                "total": repository_total,
                "percent": round(repository_percent, 1),
                "policy": "informational",
            },
            "cli_integration": cli_payload,
            "fault_injection": fault_payload,
            "backend_conformance": backend_payload,
            "differential_policy": {
                "cases": 6144,
                "cases_per_seed": 1536,
                "seeds": [20260710, 20260711, 20260712, 20260713],
                "reference": "mustache.js",
            },
        },
        "publication": {
            "mooncakes_version": mooncakes_version,
            "mooncakes_build_status": mooncakes_build_status,
            "mooncakes_downloads": mooncakes_downloads,
            "mooncakes_docs_url": mooncakes_docs_url,
            "latest_github_workflow": {
                "conclusion": workflow_conclusion,
                "commit": workflow_sha,
                "url": workflow_url,
            },
        },
    }
    JSON_PATH.write_text(json.dumps(machine_payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {DOC_PATH}")
    print(f"Wrote {JSON_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
