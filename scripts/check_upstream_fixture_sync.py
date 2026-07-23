from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "third_party" / "mustache-spec" / "MANIFEST.json"
DEFAULT_API_URL = "https://api.github.com/repos/mustache/spec/commits?path=specs&per_page=1"


def fetch_latest_specs_commit(api_url: str) -> dict[str, str]:
    request = urllib.request.Request(
        api_url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "moon-mustache-upstream-sync-check",
        },
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        payload = json.load(response)
    if not isinstance(payload, list) or not payload or not isinstance(payload[0], dict):
        raise ValueError("upstream API returned no commit entries")
    entry = payload[0]
    sha = entry.get("sha")
    commit = entry.get("commit")
    if not isinstance(sha, str) or not isinstance(commit, dict):
        raise ValueError("upstream API response is missing commit metadata")
    author = commit.get("author")
    date = author.get("date") if isinstance(author, dict) else None
    return {
        "commit": sha,
        "commit_date": date if isinstance(date, str) else "",
    }


def build_report(manifest: dict[str, object], latest: dict[str, str]) -> dict[str, object]:
    upstream = manifest.get("upstream")
    if not isinstance(upstream, dict):
        raise ValueError("manifest upstream metadata is missing")
    pinned = upstream.get("commit")
    repository = upstream.get("repository")
    if not isinstance(pinned, str) or not isinstance(repository, str):
        raise ValueError("manifest upstream metadata is incomplete")
    latest_commit = latest["commit"]
    status = "up_to_date" if latest_commit == pinned else "newer_available"
    return {
        "schema_version": 1,
        "checked_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "repository": repository,
        "scope": "specs",
        "pinned_commit": pinned,
        "latest_specs_commit": latest_commit,
        "latest_specs_commit_date": latest.get("commit_date", ""),
        "status": status,
        "action": (
            "No fixture regeneration is needed."
            if status == "up_to_date"
            else "Review upstream changes, then regenerate and verify fixtures deliberately."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Detect newer mustache/spec fixture commits")
    parser.add_argument("--json-output", type=Path)
    parser.add_argument("--api-url", default=DEFAULT_API_URL, help=argparse.SUPPRESS)
    args = parser.parse_args()

    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
        report = build_report(manifest, fetch_latest_specs_commit(args.api_url))
    except (OSError, ValueError, TypeError, json.JSONDecodeError, urllib.error.URLError) as error:
        print(f"Upstream fixture sync check failed: {error}", file=sys.stderr)
        return 1

    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")

    if report["status"] == "up_to_date":
        print(f"Upstream fixture pin is current: {report['pinned_commit'][:12]}")
    else:
        print(
            "Upstream fixture update available: "
            f"pinned {report['pinned_commit'][:12]}, latest {report['latest_specs_commit'][:12]}"
        )
        print(report["action"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
