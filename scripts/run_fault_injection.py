from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEST_SUMMARY_RE = re.compile(r"Total tests:\s*(\d+), passed:\s*(\d+), failed:\s*(\d+)\.")


@dataclass(frozen=True)
class Mutation:
    name: str
    file: str
    old: str
    new: str
    expected_occurrences: int
    test_file: str
    test_filter: str
    risk: str


MUTATIONS = [
    Mutation(
        name="disable repeated ampersand escaping",
        file="src/escape.mbt",
        old='.replace_all(old="&", new="&amp;")',
        new='.replace_all(old="&", new="&")',
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*escape_html handles reserved characters*",
        risk="unsafe or reference-incompatible HTML output",
    ),
    Mutation(
        name="make true booleans falsey",
        file="src/context.mbt",
        old="BoolValue(v) => v",
        new="BoolValue(_) => false",
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*true boolean section renders children*",
        risk="reversed section behavior",
    ),
    Mutation(
        name="allow parent-directory traversal",
        file="src/path_utils.mbt",
        old=(
            '    if segment == ".." {\n'
            '      return Err("parent traversal is not allowed: " + path)\n'
            "    }"
        ),
        new='    if segment == ".." {\n      continue\n    }',
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*normalize_bundle_path rewrites separators and rejects traversal*",
        risk="bundle output escaping its destination directory",
    ),
    Mutation(
        name="disable partial-depth guard",
        file="src/renderer.mbt",
        old="if depth >= options.partial_depth_limit {",
        new="if false {",
        expected_occurrences=2,
        test_file="src/mustache_test.mbt",
        test_filter="*render resource budget limits partial depth*",
        risk="unbounded recursive partial expansion",
    ),
    Mutation(
        name="disable output-length guard",
        file="src/renderer.mbt",
        old="if text.length() <= remaining {",
        new="if true {",
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*render resource budget limits output length*",
        risk="unbounded generated output exhausting memory or downstream storage",
    ),
    Mutation(
        name="disable section-iteration guard",
        file="src/renderer.mbt",
        old="if budget.section_iterations[0] > options.max_section_iterations {",
        new="if false {",
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*render resource budget limits section iterations*",
        risk="unbounded collection expansion consuming time and output budget",
    ),
    Mutation(
        name="disable render-step guard",
        file="src/renderer.mbt",
        old="if budget.steps[0] > options.max_render_steps {",
        new="if false {",
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*render resource budget limits total render steps*",
        risk="complex templates bypassing deterministic work limits",
    ),
    Mutation(
        name="disable parent-context fallback",
        file="src/context.mbt",
        old="while index > 0 {",
        new="while index > stack.length() - 1 {",
        expected_occurrences=1,
        test_file="src/mustache_test.mbt",
        test_filter="*array section can still read parent scope values*",
        risk="nested sections losing values from their parent context",
    ),
]


def write_junit(path: Path, results: list[dict[str, object]]) -> None:
    survived = sum(result["status"] == "survived" for result in results)
    invalid = sum(result["status"] == "invalid" for result in results)
    duration_seconds = sum(int(result["duration_ms"]) for result in results) / 1000
    suite = ET.Element(
        "testsuite",
        {
            "name": "moon-mustache controlled fault injection",
            "tests": str(len(results)),
            "failures": str(survived),
            "errors": str(invalid),
            "time": f"{duration_seconds:.3f}",
        },
    )
    for result in results:
        case = ET.SubElement(
            suite,
            "testcase",
            {
                "classname": str(result["file"]),
                "name": str(result["name"]),
                "time": f"{int(result['duration_ms']) / 1000:.3f}",
            },
        )
        status = result["status"]
        if status == "survived":
            failure = ET.SubElement(
                case,
                "failure",
                {"type": "survived", "message": str(result["risk"])},
            )
            failure.text = str(result["output_tail"])
        elif status == "invalid":
            error = ET.SubElement(
                case,
                "error",
                {"type": "invalid", "message": "mutation result was not a test failure"},
            )
            error.text = str(result["output_tail"])
        output = ET.SubElement(case, "system-out")
        output.text = (
            f"risk: {result['risk']}\n"
            f"detector: {result['test_file']} {result['test_filter']}\n"
            f"status: {status}\n{result['output_tail']}"
        )
    tree = ET.ElementTree(suite)
    ET.indent(tree, space="  ")
    path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(path, encoding="utf-8", xml_declaration=True)


def moon_command() -> str:
    for candidate in ("moon", "moon.exe", "moon.cmd"):
        found = shutil.which(candidate)
        if found:
            return found
    raise RuntimeError("MoonBit executable `moon` was not found on PATH")


def tracked_files() -> list[Path]:
    completed = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    )
    return [Path(item.decode("utf-8")) for item in completed.stdout.split(b"\0") if item]


def copy_project(destination: Path) -> None:
    for relative in tracked_files():
        source = ROOT / relative
        if not source.is_file():
            continue
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def apply_mutation(project: Path, mutation: Mutation) -> bytes:
    path = project / mutation.file
    original = path.read_bytes()
    text = original.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")
    occurrences = text.count(mutation.old)
    if occurrences != mutation.expected_occurrences:
        raise RuntimeError(
            f"mutation target drifted for {mutation.name!r}: "
            f"expected {mutation.expected_occurrences} occurrence(s), found {occurrences}"
        )
    path.write_bytes(text.replace(mutation.old, mutation.new, 1).encode("utf-8"))
    return original


def run_mutation(project: Path, mutation: Mutation, moon: str) -> dict[str, object]:
    path = project / mutation.file
    original = apply_mutation(project, mutation)
    command = [
        moon,
        "test",
        "--deny-warn",
        "--target",
        "wasm-gc",
        mutation.test_file,
        "--filter",
        mutation.test_filter,
    ]
    started = time.perf_counter()
    timed_out = False
    try:
        completed = subprocess.run(
            command,
            cwd=project,
            text=True,
            encoding="utf-8",
            errors="replace",
            capture_output=True,
            check=False,
            timeout=120,
        )
    except subprocess.TimeoutExpired as error:
        timed_out = True
        timeout_stdout = error.stdout or ""
        timeout_stderr = error.stderr or ""
        if isinstance(timeout_stdout, bytes):
            timeout_stdout = timeout_stdout.decode("utf-8", errors="replace")
        if isinstance(timeout_stderr, bytes):
            timeout_stderr = timeout_stderr.decode("utf-8", errors="replace")
    finally:
        path.write_bytes(original)
    duration_ms = round((time.perf_counter() - started) * 1000)
    if timed_out:
        output = timeout_stdout + ("\n" + timeout_stderr if timeout_stderr else "")
        return {
            "name": mutation.name,
            "risk": mutation.risk,
            "file": mutation.file,
            "test_file": mutation.test_file,
            "test_filter": mutation.test_filter,
            "status": "invalid",
            "exit_code": None,
            "duration_ms": duration_ms,
            "test_summary": None,
            "output_tail": "mutation test timed out\n" + "\n".join(output.splitlines()[-19:]),
        }
    output = completed.stdout + ("\n" + completed.stderr if completed.stderr else "")
    summary = TEST_SUMMARY_RE.search(output)
    if summary and int(summary.group(1)) == 0:
        status = "invalid"
    elif completed.returncode == 0:
        status = "survived"
    elif summary and int(summary.group(3)) > 0:
        status = "killed"
    else:
        status = "invalid"
    return {
        "name": mutation.name,
        "risk": mutation.risk,
        "file": mutation.file,
        "test_file": mutation.test_file,
        "test_filter": mutation.test_filter,
        "status": status,
        "exit_code": completed.returncode,
        "duration_ms": duration_ms,
        "test_summary": summary.group(0) if summary else None,
        "output_tail": "\n".join(output.splitlines()[-20:]),
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Prove that focused Moon Mustache regression tests reject controlled faults"
    )
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--junit-output", type=Path)
    args = parser.parse_args()

    moon = moon_command()
    with tempfile.TemporaryDirectory(prefix="moon-mustache-faults-") as directory:
        project = Path(directory)
        copy_project(project)
        results = [run_mutation(project, mutation, moon) for mutation in MUTATIONS]

    killed = sum(result["status"] == "killed" for result in results)
    survived = sum(result["status"] == "survived" for result in results)
    invalid = sum(result["status"] == "invalid" for result in results)
    payload = {
        "schema_version": 1,
        "suite": "moon-mustache controlled fault injection",
        "killed": killed,
        "survived": survived,
        "invalid": invalid,
        "total": len(results),
        "passed": killed == len(results),
        "mutations": results,
    }
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    if args.junit_output:
        write_junit(args.junit_output, results)

    for result in results:
        print(f"{result['status'].upper():8} {result['name']} ({result['duration_ms']} ms)")
    print(f"Fault injection: {killed}/{len(results)} killed, {survived} survived, {invalid} invalid")
    return 0 if payload["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
