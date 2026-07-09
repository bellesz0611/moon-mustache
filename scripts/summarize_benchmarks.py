from __future__ import annotations

import json
import sys
from pathlib import Path


def format_float(value: float) -> str:
    return f"{value:.10f}"


def read_json_text(path: Path) -> str:
    raw = path.read_bytes()
    for encoding in ("utf-8-sig", "utf-16", "utf-16-le", "utf-16-be"):
        try:
            return raw.decode(encoding)
        except UnicodeDecodeError:
            pass
    return raw.decode("utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: python scripts/summarize_benchmarks.py <benchmarks.json>", file=sys.stderr)
        return 1

    input_path = Path(sys.argv[1])
    payload = json.loads(read_json_text(input_path))

    print("# Benchmark Summary")
    print()
    print(f"Source: `{input_path.name}`")
    print()
    print("| Workload | Mean | Median | Runs | Batch Size | Std Dev % |")
    print("| --- | ---: | ---: | ---: | ---: | ---: |")
    for entry in payload:
        print(
            "| "
            + entry["name"]
            + " | "
            + format_float(entry["mean"])
            + " | "
            + format_float(entry["median"])
            + " | "
            + str(entry["runs"])
            + " | "
            + str(entry["batch_size"])
            + " | "
            + format_float(entry["std_dev_pct"])
            + " |"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
