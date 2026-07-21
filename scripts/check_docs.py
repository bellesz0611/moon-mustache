from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
SKIP_PARTS = {".git", "_build", "node_modules", "tmp"}
LINK_RE = re.compile(r"!?\[[^\]]*\]\((<[^>]+>|[^)\s]+)(?:\s+['\"][^'\"]*['\"])?\)")
SCHEMES = ("http://", "https://", "mailto:", "data:")


def markdown_files() -> list[Path]:
    return sorted(
        path
        for path in ROOT.rglob("*.md")
        if not any(part in SKIP_PARTS for part in path.relative_to(ROOT).parts)
    )


def local_target(source: Path, raw_target: str) -> tuple[Path | None, str | None]:
    target = raw_target.strip("<>")
    if not target or target.startswith("#") or target.lower().startswith(SCHEMES):
        return None, None
    if re.match(r"^[A-Za-z]:[\\/]", target) or target.startswith("file:"):
        return None, "machine-local absolute path"
    target = unquote(target.split("#", 1)[0].split("?", 1)[0])
    if not target:
        return None, None
    return (source.parent / target).resolve(), None


def check_file(path: Path) -> list[str]:
    errors: list[str] = []
    in_fence = False
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for match in LINK_RE.finditer(line):
            raw_target = match.group(1)
            target, error = local_target(path, raw_target)
            relative = path.relative_to(ROOT)
            if error:
                errors.append(f"{relative}:{line_number}: {error}: {raw_target}")
            elif target is not None and not target.exists():
                errors.append(f"{relative}:{line_number}: missing local target: {raw_target}")
    return errors


def main() -> int:
    files = markdown_files()
    errors = [error for path in files for error in check_file(path)]
    if errors:
        print("Documentation validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Documentation validation passed: {len(files)} Markdown files, no broken local links")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
