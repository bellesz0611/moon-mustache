from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOLDEN_PATH = ROOT / "backend_conformance" / "golden.txt"
DEFAULT_TARGETS = ("wasm", "wasm-gc", "js")
VALID_TARGETS = ("wasm", "wasm-gc", "js", "native")


def moon_command() -> str:
    for candidate in ("moon", "moon.exe", "moon.cmd"):
        found = shutil.which(candidate)
        if found:
            return found
    raise RuntimeError("MoonBit executable `moon` was not found on PATH")


def normalized(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def parse_targets(raw: str, require_native: bool) -> list[str]:
    targets = [item.strip() for item in raw.split(",") if item.strip()]
    if require_native and "native" not in targets:
        targets.append("native")
    invalid = [target for target in targets if target not in VALID_TARGETS]
    if invalid:
        raise ValueError(f"unsupported target(s): {', '.join(invalid)}")
    if len(targets) < 2:
        raise ValueError("backend conformance requires at least two targets")
    return targets


def diff(expected: str, actual: str, target: str) -> str:
    return "".join(
        difflib.unified_diff(
            expected.splitlines(keepends=True),
            actual.splitlines(keepends=True),
            fromfile="backend_conformance/golden.txt",
            tofile=f"{target} output",
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare one deterministic Moon Mustache corpus across MoonBit backends"
    )
    parser.add_argument("--targets", default=",".join(DEFAULT_TARGETS))
    parser.add_argument("--require-native", action="store_true")
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    try:
        targets = parse_targets(args.targets, args.require_native)
    except ValueError as error:
        parser.error(str(error))
    golden = normalized(GOLDEN_PATH.read_text(encoding="utf-8"))
    moon = moon_command()
    results: list[dict[str, object]] = []
    outputs: dict[str, str] = {}
    for target in targets:
        started = time.perf_counter()
        completed = subprocess.run(
            [moon, "run", "--target", target, "backend_conformance"],
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            errors="replace",
            capture_output=True,
            check=False,
        )
        duration_ms = round((time.perf_counter() - started) * 1000)
        output = normalized(completed.stdout)
        outputs[target] = output
        matches_golden = completed.returncode == 0 and output == golden
        results.append(
            {
                "target": target,
                "status": "passed" if matches_golden else "failed",
                "exit_code": completed.returncode,
                "duration_ms": duration_ms,
                "sha256": hashlib.sha256(output.encode("utf-8")).hexdigest(),
                "matches_golden": matches_golden,
                "stderr": completed.stderr,
                "diff": "" if matches_golden else diff(golden, output, target),
            }
        )

    baseline = outputs[targets[0]]
    cross_backend_equal = all(outputs[target] == baseline for target in targets[1:])
    passed = all(result["status"] == "passed" for result in results) and cross_backend_equal
    payload = {
        "schema_version": 1,
        "suite": "moon-mustache backend golden conformance",
        "golden": "backend_conformance/golden.txt",
        "targets": targets,
        "cross_backend_equal": cross_backend_equal,
        "passed": passed,
        "results": results,
    }
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    for result in results:
        print(
            f"{result['status'].upper():6} {result['target']} "
            f"sha256={str(result['sha256'])[:12]} ({result['duration_ms']} ms)"
        )
        if result["status"] == "failed":
            if result["stderr"]:
                print(result["stderr"], file=sys.stderr)
            if result["diff"]:
                print(result["diff"], file=sys.stderr)
    print(
        f"Backend conformance: {sum(item['status'] == 'passed' for item in results)}/"
        f"{len(results)} targets match golden; cross-backend equal={str(cross_backend_equal).lower()}"
    )
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
