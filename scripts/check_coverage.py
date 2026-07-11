from __future__ import annotations

import re
import sys
from pathlib import Path


LINE_RE = re.compile(r"^src[\\/].*:\s*(\d+)/(\d+)\s*$")


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: check_coverage.py <summary-file> [minimum-percent]", file=sys.stderr)
        return 2

    summary_path = Path(sys.argv[1])
    minimum = float(sys.argv[2]) if len(sys.argv) > 2 else 80.0
    covered = 0
    total = 0
    for line in summary_path.read_text(encoding="utf-8").splitlines():
        match = LINE_RE.match(line.strip())
        if match:
            covered += int(match.group(1))
            total += int(match.group(2))

    if total == 0:
        print("No src/ coverage entries were found.", file=sys.stderr)
        return 2

    percent = covered * 100.0 / total
    print(f"MoonBit src coverage: {covered}/{total} ({percent:.1f}%), required {minimum:.1f}%")
    if percent < minimum:
        print("Coverage gate failed.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
