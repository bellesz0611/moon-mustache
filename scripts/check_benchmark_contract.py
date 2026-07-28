from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

from summarize_benchmarks import read_json_text


EXPECTED_WORKLOADS = (
    "plain_render",
    "section_render",
    "partial_render",
    "prepared_partial_render",
    "json_bundle_render",
    "strict_missing_render",
)
FLOAT_FIELDS = ("min", "max", "mean", "median", "std_dev_pct")
INTEGER_FIELDS = ("runs", "batch_size")


def validate_payload(payload: object) -> dict[str, object]:
    errors: list[str] = []
    entries: list[dict[str, object]] = []
    if not isinstance(payload, list):
        return {
            "schema_version": 1,
            "suite": "benchmark contract",
            "expected_workloads": list(EXPECTED_WORKLOADS),
            "workloads": [],
            "passed": False,
            "errors": ["benchmark payload must be a JSON array"],
        }

    names: list[str] = []
    for index, raw_entry in enumerate(payload):
        if not isinstance(raw_entry, dict):
            errors.append(f"entry {index} must be an object")
            continue
        entry_errors: list[str] = []
        name = raw_entry.get("name")
        if not isinstance(name, str) or not name:
            entry_errors.append("name must be a non-empty string")
            name = f"<entry-{index}>"
        else:
            names.append(name)

        for field in FLOAT_FIELDS:
            value = raw_entry.get(field)
            if isinstance(value, bool) or not isinstance(value, (int, float)):
                entry_errors.append(f"{field} must be numeric")
            elif not math.isfinite(float(value)) or float(value) < 0:
                entry_errors.append(f"{field} must be finite and non-negative")

        for field in INTEGER_FIELDS:
            value = raw_entry.get(field)
            if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                entry_errors.append(f"{field} must be a positive integer")

        minimum = raw_entry.get("min")
        maximum = raw_entry.get("max")
        mean = raw_entry.get("mean")
        median = raw_entry.get("median")
        if all(
            isinstance(value, (int, float)) and not isinstance(value, bool)
            for value in (minimum, maximum, mean, median)
        ):
            if minimum > maximum:
                entry_errors.append("min must not exceed max")
            if not minimum <= mean <= maximum:
                entry_errors.append("mean must be between min and max")
            if not minimum <= median <= maximum:
                entry_errors.append("median must be between min and max")

        errors.extend(f"{name}: {message}" for message in entry_errors)
        entries.append(
            {
                "name": name,
                "status": "passed" if not entry_errors else "failed",
                "errors": entry_errors,
            }
        )

    duplicate_names = sorted({name for name in names if names.count(name) > 1})
    if duplicate_names:
        errors.append(f"duplicate workloads: {duplicate_names}")
    expected = set(EXPECTED_WORKLOADS)
    actual = set(names)
    if expected - actual:
        errors.append(f"missing workloads: {sorted(expected - actual)}")
    if actual - expected:
        errors.append(f"unexpected workloads: {sorted(actual - expected)}")

    return {
        "schema_version": 1,
        "suite": "benchmark contract",
        "expected_workloads": list(EXPECTED_WORKLOADS),
        "workloads": entries,
        "passed": not errors,
        "errors": errors,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Moon Mustache benchmark output")
    parser.add_argument("input", type=Path)
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    try:
        payload = json.loads(read_json_text(args.input))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        print(f"Benchmark contract failed: {error}", file=sys.stderr)
        return 1

    report = validate_payload(payload)
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    if not report["passed"]:
        print("Benchmark contract failed:", file=sys.stderr)
        for error in report["errors"]:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Benchmark contract passed: {len(report['workloads'])} workloads")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
