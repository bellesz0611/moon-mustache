from __future__ import annotations

import re
import sys
from pathlib import Path


ENTRY_RE = re.compile(r"^(.+\.mbt):\s*(\d+)/(\d+)\s*$")
TOTAL_RE = re.compile(r"^Total:\s*(\d+)/(\d+)\s*$")


def parse_core_coverage(summary: str) -> tuple[int, int]:
    repository_covered = None
    repository_total = None
    non_core_covered = 0
    non_core_total = 0
    for line in summary.splitlines():
        stripped = line.strip()
        total_match = TOTAL_RE.match(stripped)
        if total_match:
            repository_covered = int(total_match.group(1))
            repository_total = int(total_match.group(2))
            continue
        entry_match = ENTRY_RE.match(stripped)
        if not entry_match:
            continue
        path = entry_match.group(1).replace("\\", "/")
        if not path.startswith("src/"):
            non_core_covered += int(entry_match.group(2))
            non_core_total += int(entry_match.group(3))

    if repository_total is None or repository_covered is None:
        raise ValueError("No repository coverage total was found.")
    # MoonBit omits 100%-covered files from summary rows but keeps them in Total.
    # The coverage job instruments non-core packages at 0%, so subtracting their
    # explicit rows preserves fully covered src/ files in the core denominator.
    return repository_covered - non_core_covered, repository_total - non_core_total


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: check_coverage.py <summary-file> [minimum-percent]", file=sys.stderr)
        return 2

    summary_path = Path(sys.argv[1])
    minimum = float(sys.argv[2]) if len(sys.argv) > 2 else 80.0
    try:
        covered, total = parse_core_coverage(summary_path.read_text(encoding="utf-8"))
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 2

    percent = covered * 100.0 / total
    print(f"MoonBit src coverage: {covered}/{total} ({percent:.1f}%), required {minimum:.1f}%")
    if percent < minimum:
        print("Coverage gate failed.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
