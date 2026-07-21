from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

from generate_official_spec_fixtures import SUITES, render_fixture_source


ROOT = Path(__file__).resolve().parents[1]
FIXTURE_ROOT = ROOT / "third_party" / "mustache-spec"
MANIFEST_PATH = FIXTURE_ROOT / "MANIFEST.json"


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def canonical_text_bytes(content: bytes) -> bytes:
    """Return UTF-8 text with line endings normalized for cross-platform hashes."""
    text = content.decode("utf-8").replace("\r\n", "\n").replace("\r", "\n")
    return text.encode("utf-8")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify pinned mustache/spec fixture integrity")
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    errors: list[str] = []
    fixture_results: list[dict[str, object]] = []
    declared_paths = {entry["path"] for entry in manifest["fixtures"]}
    actual_paths = {
        path.relative_to(FIXTURE_ROOT).as_posix()
        for path in (FIXTURE_ROOT / "specs").glob("*.json")
    }
    if declared_paths != actual_paths:
        fail(
            errors,
            "fixture file set differs from manifest: "
            f"missing={sorted(declared_paths - actual_paths)}, "
            f"unexpected={sorted(actual_paths - declared_paths)}",
        )

    total_tests = 0
    for entry in manifest["fixtures"]:
        path = FIXTURE_ROOT / entry["path"]
        if not path.is_file():
            fail(errors, f"missing fixture: {entry['path']}")
            continue
        content = path.read_bytes()
        digest = sha256_bytes(canonical_text_bytes(content))
        payload = json.loads(content)
        test_count = len(payload.get("tests", []))
        total_tests += test_count
        if digest != entry["sha256"]:
            fail(errors, f"checksum mismatch: {entry['path']}")
        if test_count != entry["tests"]:
            fail(
                errors,
                f"test count mismatch: {entry['path']} "
                f"expected={entry['tests']} actual={test_count}",
            )
        fixture_results.append(
            {
                "path": entry["path"],
                "sha256": digest,
                "tests": test_count,
                "status": "passed"
                if digest == entry["sha256"] and test_count == entry["tests"]
                else "failed",
            }
        )

    if total_tests != manifest["total_tests"]:
        fail(
            errors,
            f"total test count mismatch: expected={manifest['total_tests']} actual={total_tests}",
        )

    manifest_suites = [Path(entry["path"]).stem for entry in manifest["fixtures"]]
    if manifest_suites != SUITES:
        fail(errors, "generator suite order differs from manifest")

    license_path = FIXTURE_ROOT / manifest["license"]["path"]
    license_digest = sha256_bytes(canonical_text_bytes(license_path.read_bytes()))
    if license_digest != manifest["license"]["sha256"]:
        fail(errors, "license checksum mismatch")

    generated_path = ROOT / manifest["generated_source"]["path"]
    expected_generated = render_fixture_source().encode("utf-8")
    actual_generated = canonical_text_bytes(generated_path.read_bytes())
    generated_digest = sha256_bytes(actual_generated)
    if actual_generated != expected_generated:
        fail(errors, "generated MoonBit fixture source is stale")
    if generated_digest != manifest["generated_source"]["sha256"]:
        fail(errors, "generated MoonBit fixture checksum mismatch")

    report = {
        "schema_version": 1,
        "suite": "mustache/spec fixture integrity",
        "upstream": manifest["upstream"],
        "fixtures": fixture_results,
        "total_tests": total_tests,
        "license_sha256": license_digest,
        "generated_source_sha256": generated_digest,
        "passed": len(errors) == 0,
        "errors": errors,
    }
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    if errors:
        print("Official fixture integrity failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        f"Official fixture integrity passed: {len(fixture_results)} files, "
        f"{total_tests} cases, upstream {manifest['upstream']['commit'][:12]}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
