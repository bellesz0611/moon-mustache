from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

from check_coverage import parse_core_coverage


ROOT = Path(__file__).resolve().parents[1]
TOTAL_RE = re.compile(r"^Total:\s*(\d+)/(\d+)\s*$", re.MULTILINE)


def moon_command() -> str:
    for candidate in ("moon", "moon.exe", "moon.cmd"):
        found = shutil.which(candidate)
        if found:
            return found
    raise RuntimeError("MoonBit executable `moon` was not found on PATH")


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        if completed.stdout:
            print(completed.stdout, file=sys.stderr)
        if completed.stderr:
            print(completed.stderr, file=sys.stderr)
        raise RuntimeError(f"command failed ({completed.returncode}): {' '.join(command)}")
    return completed


def main() -> int:
    parser = argparse.ArgumentParser(description="Collect and enforce Moon Mustache core coverage")
    parser.add_argument("--minimum", type=float, default=88.0)
    parser.add_argument("--cli-core-minimum", type=float, default=70.0)
    parser.add_argument("--output-dir", type=Path, default=ROOT / "_artifacts" / "coverage")
    args = parser.parse_args()

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    moon = moon_command()

    run([moon, "coverage", "clean"])
    test = run([moon, "test", "--enable-coverage", "--target", "wasm-gc"])
    summary = run([moon, "coverage", "report", "-f", "summary"]).stdout
    (output_dir / "coverage-summary.txt").write_text(summary, encoding="utf-8")
    core_summary = run(
        [
            moon,
            "coverage",
            "report",
            "-f",
            "summary",
            "-p",
            "bellesz0611/moon-mustache/src",
        ]
    ).stdout
    (output_dir / "coverage-core-summary.txt").write_text(core_summary, encoding="utf-8")
    cli_core_summary = run(
        [
            moon,
            "coverage",
            "report",
            "-f",
            "summary",
            "-p",
            "bellesz0611/moon-mustache/cli_core",
        ]
    ).stdout
    (output_dir / "coverage-cli-core-summary.txt").write_text(
        cli_core_summary,
        encoding="utf-8",
    )
    cobertura_path = output_dir / "coverage.xml"
    run(
        [
            moon,
            "coverage",
            "report",
            "-f",
            "cobertura",
            "-o",
            str(cobertura_path),
        ]
    )

    core_covered, core_total = parse_core_coverage(core_summary)
    total_match = TOTAL_RE.search(summary)
    if not total_match:
        raise RuntimeError("repository coverage total is missing")
    repository_covered = int(total_match.group(1))
    repository_total = int(total_match.group(2))
    core_percent = core_covered * 100.0 / core_total
    cli_total_match = TOTAL_RE.search(cli_core_summary)
    if not cli_total_match:
        raise RuntimeError("CLI testable-core coverage total is missing")
    cli_core_covered = int(cli_total_match.group(1))
    cli_core_total = int(cli_total_match.group(2))
    cli_core_percent = cli_core_covered * 100.0 / cli_core_total
    payload = {
        "schema_version": 1,
        "test_command": "moon test --enable-coverage --target wasm-gc",
        "test_summary": test.stdout.strip(),
        "core": {
            "covered": core_covered,
            "total": core_total,
            "percent": round(core_percent, 1),
            "minimum_percent": args.minimum,
        },
        "cli_core": {
            "covered": cli_core_covered,
            "total": cli_core_total,
            "percent": round(cli_core_percent, 1),
            "minimum_percent": args.cli_core_minimum,
            "scope": "pure CLI parsing, diagnostics, report selection, path composition, and output-blocking decisions",
        },
        "repository": {
            "covered": repository_covered,
            "total": repository_total,
            "percent": round(repository_covered * 100.0 / repository_total, 1),
            "policy": "informational",
        },
    }
    (output_dir / "coverage.json").write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"MoonBit core coverage: {core_covered}/{core_total} "
        f"({core_percent:.1f}%), required {args.minimum:.1f}%"
    )
    print(
        f"CLI testable-core coverage: {cli_core_covered}/{cli_core_total} "
        f"({cli_core_percent:.1f}%), required {args.cli_core_minimum:.1f}%"
    )
    print(f"Coverage evidence: {output_dir}")
    if core_percent < args.minimum or cli_core_percent < args.cli_core_minimum:
        print("Coverage gate failed.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
