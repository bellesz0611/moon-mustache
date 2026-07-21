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
    parser.add_argument("--output-dir", type=Path, default=ROOT / "_artifacts" / "coverage")
    args = parser.parse_args()

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    moon = moon_command()

    run([moon, "coverage", "clean"])
    test = run([moon, "test", "--enable-coverage", "--target", "wasm-gc"])
    summary = run([moon, "coverage", "report", "-f", "summary"]).stdout
    (output_dir / "coverage-summary.txt").write_text(summary, encoding="utf-8")
    run(
        [
            moon,
            "coverage",
            "report",
            "-f",
            "cobertura",
            "-o",
            str(output_dir / "coverage.xml"),
        ]
    )

    core_covered, core_total = parse_core_coverage(summary)
    total_match = TOTAL_RE.search(summary)
    if not total_match:
        raise RuntimeError("repository coverage total is missing")
    repository_covered = int(total_match.group(1))
    repository_total = int(total_match.group(2))
    core_percent = core_covered * 100.0 / core_total
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
    print(f"Coverage evidence: {output_dir}")
    if core_percent < args.minimum:
        print("Coverage gate failed.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
