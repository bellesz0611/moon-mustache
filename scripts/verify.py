from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def executable(*candidates: str) -> str:
    for candidate in candidates:
        found = shutil.which(candidate)
        if found:
            return found
    raise RuntimeError(f"required executable not found: {candidates[0]}")


def command_label(command: list[str]) -> str:
    return " ".join(command)


def run_step(name: str, command: list[str], cwd: Path, logs: Path) -> dict[str, object]:
    print(f"\n== {name} ==")
    print(f"$ {command_label(command)}")
    started = time.perf_counter()
    completed = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
    )
    duration_ms = round((time.perf_counter() - started) * 1000)
    output = completed.stdout
    if completed.stderr:
        output += ("\n" if output else "") + completed.stderr
    log_path = logs / f"{name.replace(' ', '-').lower()}.log"
    log_path.write_text(output, encoding="utf-8")
    status = "passed" if completed.returncode == 0 else "failed"
    print(f"{status.upper()} ({duration_ms} ms) -> {log_path.relative_to(ROOT)}")
    if completed.returncode != 0:
        tail = "\n".join(output.splitlines()[-20:])
        if tail:
            print(tail, file=sys.stderr)
    return {
        "name": name,
        "status": status,
        "exit_code": completed.returncode,
        "duration_ms": duration_ms,
        "command": command,
        "cwd": str(cwd.relative_to(ROOT)) if cwd != ROOT else ".",
        "log": str(log_path.relative_to(ROOT)).replace("\\", "/"),
    }


def skipped_step(name: str, reason: str) -> dict[str, object]:
    return {
        "name": name,
        "status": "skipped",
        "reason": reason,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Reproducible Moon Mustache acceptance suite")
    parser.add_argument(
        "--profile",
        choices=("quick", "full"),
        default="quick",
        help="full also runs every MoonBit backend plus playground differential/build",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=ROOT / "_artifacts" / "verification",
        help="artifact directory (default: _artifacts/verification)",
    )
    args = parser.parse_args()

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    logs = output_dir / "logs"
    logs.mkdir(parents=True, exist_ok=True)

    moon = executable("moon", "moon.exe", "moon.cmd")
    python = sys.executable
    steps: list[tuple[str, list[str], Path]] = [
        ("documentation", [python, "scripts/check_docs.py"], ROOT),
        (
            "official fixture integrity",
            [
                python,
                "scripts/verify_official_spec_fixtures.py",
                "--json-output",
                str(output_dir / "official-fixture-integrity.json"),
            ],
            ROOT,
        ),
        ("format", [moon, "fmt", "--check"], ROOT),
        ("check wasm-gc", [moon, "check", "--deny-warn", "--target", "wasm-gc"], ROOT),
        ("test wasm-gc", [moon, "test", "--deny-warn", "--target", "wasm-gc"], ROOT),
        ("official spec", [moon, "run", "--target", "wasm-gc", "official_spec_report"], ROOT),
        (
            "CLI integration",
            [python, "scripts/test_cli_integration.py", "--json-output", str(output_dir / "cli-integration.json")],
            ROOT,
        ),
    ]

    skipped: list[dict[str, object]] = []
    if args.profile == "full":
        for target in ("wasm", "js"):
            steps.extend(
                [
                    (f"check {target}", [moon, "check", "--deny-warn", "--target", target], ROOT),
                    (f"build {target}", [moon, "build", "--deny-warn", "--target", target], ROOT),
                    (f"test {target}", [moon, "test", "--deny-warn", "--target", target], ROOT),
                ]
            )
        steps.append(("check native", [moon, "check", "--deny-warn", "--target", "native"], ROOT))
        if any(shutil.which(compiler) for compiler in ("cl", "cc", "gcc", "clang")):
            steps.extend(
                [
                    ("build native", [moon, "build", "--deny-warn", "--target", "native"], ROOT),
                    ("test native", [moon, "test", "--deny-warn", "--target", "native"], ROOT),
                ]
            )
        else:
            reason = "no local C compiler found (CI still enforces native build and test)"
            skipped.extend(
                [
                    skipped_step("build native", reason),
                    skipped_step("test native", reason),
                ]
            )
        npm = executable("npm", "npm.cmd")
        steps.extend(
            [
                (
                    "coverage",
                    [
                        python,
                        "scripts/run_coverage.py",
                        "--minimum",
                        "88",
                        "--output-dir",
                        str(output_dir / "coverage"),
                    ],
                    ROOT,
                ),
                (
                    "differential",
                    [
                        npm,
                        "run",
                        "differential",
                        "--",
                        "--json-output",
                        str(output_dir / "differential.json"),
                        "--failure-output",
                        str(output_dir / "differential-failures.json"),
                    ],
                    ROOT / "playground",
                ),
                ("playground build", [npm, "run", "build"], ROOT / "playground"),
            ]
        )

    started_at = datetime.now(timezone.utc).isoformat(timespec="seconds")
    results = [run_step(name, command, cwd, logs) for name, command, cwd in steps]
    for step in skipped:
        print(f"\n== {step['name']} ==")
        print(f"SKIPPED: {step['reason']}")
    results.extend(skipped)
    passed = sum(step["status"] == "passed" for step in results)
    failed = sum(step["status"] == "failed" for step in results)
    skipped_count = sum(step["status"] == "skipped" for step in results)
    payload = {
        "schema_version": 1,
        "profile": args.profile,
        "started_at": started_at,
        "passed": passed,
        "failed": failed,
        "skipped": skipped_count,
        "total": len(results),
        "steps": results,
    }
    summary_path = output_dir / "verification.json"
    summary_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(
        f"\nVerification: {passed} passed, {failed} failed, "
        f"{skipped_count} skipped ({payload['total']} total)"
    )
    print(f"Evidence: {summary_path}")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
