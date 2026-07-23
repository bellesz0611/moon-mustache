from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".md", ".txt", ".json", ".yml", ".yaml", ".py", ".mbt", ".vue", ".js", ".mjs"}
PHONE_PATTERN = re.compile(r"(?<!\d)(?:\+?86[- ]?)?1[3-9]\d{9}(?!\d)")
LONG_NUMBER_PATTERN = re.compile(r"(?<!\d)(?:\d[ -]?){15,18}\d(?!\d)")
IDENTITY_PATTERN = re.compile(r"(?<!\d)\d{17}[\dXx](?!\d)")
IDENTITY_WEIGHTS = (7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2)
IDENTITY_CHECKS = "10X98765432"


def should_scan(path: Path) -> bool:
    return path.suffix.lower() in TEXT_SUFFIXES


def luhn_valid(value: str) -> bool:
    digits = [int(char) for char in value if char.isdigit()]
    if not 16 <= len(digits) <= 19:
        return False
    checksum = 0
    parity = len(digits) % 2
    for index, digit in enumerate(digits):
        if index % 2 == parity:
            digit *= 2
            if digit > 9:
                digit -= 9
        checksum += digit
    return checksum % 10 == 0


def identity_valid(value: str) -> bool:
    normalized = value.upper()
    if len(normalized) != 18 or not normalized[:17].isdigit():
        return False
    try:
        datetime.strptime(normalized[6:14], "%Y%m%d")
    except ValueError:
        return False
    checksum = sum(int(digit) * weight for digit, weight in zip(normalized[:17], IDENTITY_WEIGHTS))
    return IDENTITY_CHECKS[checksum % 11] == normalized[-1]


def labels_for_line(line: str) -> set[str]:
    labels: set[str] = set()
    if PHONE_PATTERN.search(line):
        labels.add("phone number")
    identity_values = {match.group(0).upper() for match in IDENTITY_PATTERN.finditer(line)}
    if any(identity_valid(value) for value in identity_values):
        labels.add("identity-card-like number")
    for match in LONG_NUMBER_PATTERN.finditer(line):
        value = "".join(char for char in match.group(0) if char.isdigit())
        if value not in identity_values and luhn_valid(value):
            labels.add("bank-card-like number")
    return labels


def tracked_paths() -> list[Path]:
    completed = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    )
    return [ROOT / item.decode("utf-8") for item in completed.stdout.split(b"\0") if item]


def find_matches() -> list[tuple[str, int, str]]:
    matches: list[tuple[str, int, str]] = []
    for path in tracked_paths():
        if not path.is_file() or not should_scan(path):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_number, line in enumerate(text.splitlines(), start=1):
            for label in labels_for_line(line):
                matches.append((path.relative_to(ROOT).as_posix(), line_number, label))
    return matches


def main() -> int:
    parser = argparse.ArgumentParser(description="Reject accidental personal identifiers in public text files")
    parser.add_argument("--allow", action="append", default=[], help="allow a path:line:label finding")
    args = parser.parse_args()
    allowed = set(args.allow)
    findings = [finding for finding in find_matches() if ":".join(map(str, finding)) not in allowed]
    if findings:
        print("Public PII scan failed:", file=sys.stderr)
        for path, line, label in findings:
            print(f"- {path}:{line}: {label}", file=sys.stderr)
        return 1
    print("Public PII scan passed: no phone, bank-card-like, or identity-card-like values found")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
