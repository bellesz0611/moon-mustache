from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parents[1]
GITHUB_REPOSITORY = "bellesz0611/moon-mustache"
REQUIRED_WORKFLOWS = ("check", "playground", "deploy-playground")


def run(*command: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(command),
        cwd=ROOT,
        text=True,
        encoding="utf-8",
        errors="replace",
        capture_output=True,
        check=False,
    )


def git(*args: str) -> str:
    completed = run("git", *args)
    if completed.returncode != 0:
        detail = completed.stderr.strip() or completed.stdout.strip()
        raise RuntimeError(f"git {' '.join(args)} failed: {detail}")
    return completed.stdout.strip()


def fetch_json(url: str) -> object:
    request = Request(
        url,
        headers={
            "User-Agent": "moon-mustache-submission-readiness",
            "Accept": "application/vnd.github+json",
        },
    )
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            with urlopen(request, timeout=30) as response:
                return json.load(response)
        except (HTTPError, URLError, OSError) as error:
            last_error = error
            if attempt < 2:
                time.sleep(1 + attempt)
    raise RuntimeError(f"failed to fetch {url}: {last_error}")


def add_check(
    checks: list[dict[str, object]],
    name: str,
    passed: bool,
    detail: str,
    *,
    skipped: bool = False,
) -> None:
    checks.append(
        {
            "name": name,
            "status": "skipped" if skipped else ("passed" if passed else "failed"),
            "detail": detail,
        }
    )


def gitlink_state() -> tuple[str, dict[str, str]]:
    output = git("ls-remote", "--symref", "gitlink", "HEAD", "refs/heads/main", "refs/heads/master")
    default_branch = ""
    branches: dict[str, str] = {}
    for line in output.splitlines():
        if line.startswith("ref:") and line.endswith("\tHEAD"):
            default_branch = line.split()[1].removeprefix("refs/heads/")
            continue
        fields = line.split()
        if len(fields) == 2 and fields[1].startswith("refs/heads/"):
            branches[fields[1].removeprefix("refs/heads/")] = fields[0]
    return default_branch, branches


def remote_branch_sha(remote: str, branch: str) -> str:
    output = git("ls-remote", remote, f"refs/heads/{branch}")
    fields = output.split()
    return fields[0] if len(fields) == 2 else ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate final Moon Mustache submission state")
    parser.add_argument("--offline", action="store_true", help="skip GitHub and GitLink checks")
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="report but do not fail on local uncommitted changes",
    )
    parser.add_argument("--json-output", type=Path)
    args = parser.parse_args()

    checks: list[dict[str, object]] = []
    branch = git("branch", "--show-current")
    head = git("rev-parse", "HEAD")
    short_head = head[:7]
    dirty = bool(git("status", "--short"))
    add_check(checks, "local branch", branch == "main", f"current branch: {branch}")
    add_check(
        checks,
        "clean working tree",
        not dirty or args.allow_dirty,
        "dirty changes allowed for this run" if dirty and args.allow_dirty else ("clean" if not dirty else "uncommitted changes present"),
    )
    freshness = run(sys.executable, "scripts/check_metrics_freshness.py")
    add_check(
        checks,
        "metrics freshness",
        freshness.returncode == 0,
        (freshness.stdout or freshness.stderr).strip(),
    )

    open_pull_requests: list[dict[str, object]] = []
    if args.offline:
        for name in ("GitHub main", "GitHub workflows", "GitLink main", "GitLink default branch"):
            add_check(checks, name, True, "offline mode", skipped=True)
    else:
        try:
            github_sha = remote_branch_sha("origin", "main")
            add_check(
                checks,
                "GitHub main",
                github_sha == head,
                f"local {short_head}, GitHub {github_sha[:7] or 'missing'}",
            )
        except RuntimeError as error:
            add_check(checks, "GitHub main", False, str(error))

        try:
            repository = fetch_json(f"https://api.github.com/repos/{GITHUB_REPOSITORY}")
            assert isinstance(repository, dict)
            default_branch = str(repository.get("default_branch", ""))
            add_check(
                checks,
                "GitHub default branch",
                default_branch == "main",
                f"default branch: {default_branch}",
            )
            runs_payload = fetch_json(
                f"https://api.github.com/repos/{GITHUB_REPOSITORY}/actions/runs?branch=main&per_page=100"
            )
            assert isinstance(runs_payload, dict)
            runs = runs_payload.get("workflow_runs", [])
            for workflow in REQUIRED_WORKFLOWS:
                matching = [
                    item
                    for item in runs
                    if item.get("name") == workflow
                    and item.get("head_sha") == head
                    and item.get("event") == "push"
                ]
                success = any(item.get("conclusion") == "success" for item in matching)
                add_check(
                    checks,
                    f"GitHub workflow: {workflow}",
                    success,
                    "successful push run for local HEAD" if success else f"no successful push run for {short_head}",
                )
        except (AssertionError, RuntimeError) as error:
            add_check(checks, "GitHub API", False, str(error))

        try:
            pulls = fetch_json(
                f"https://api.github.com/repos/{GITHUB_REPOSITORY}/pulls?state=open&per_page=100"
            )
            assert isinstance(pulls, list)
            open_pull_requests = [
                {
                    "number": item.get("number"),
                    "title": item.get("title"),
                    "author": item.get("user", {}).get("login"),
                    "url": item.get("html_url"),
                }
                for item in pulls
            ]
        except (AssertionError, RuntimeError) as error:
            add_check(checks, "GitHub pull requests", True, str(error), skipped=True)

        try:
            default_branch, branches = gitlink_state()
            gitlink_main = branches.get("main", "")
            add_check(
                checks,
                "GitLink main",
                gitlink_main == head,
                f"local {short_head}, GitLink {gitlink_main[:7] or 'missing'}",
            )
            default_tip = branches.get(default_branch, "")
            add_check(
                checks,
                "GitLink default branch content",
                default_branch == "main" or default_tip == head,
                (
                    f"default branch: {default_branch or 'unknown'}, "
                    f"tip: {default_tip[:7] or 'missing'}"
                ),
            )
        except RuntimeError as error:
            add_check(checks, "GitLink remote", False, str(error))

    failed = sum(item["status"] == "failed" for item in checks)
    passed = sum(item["status"] == "passed" for item in checks)
    skipped = sum(item["status"] == "skipped" for item in checks)
    payload = {
        "schema_version": 1,
        "head": head,
        "branch": branch,
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "checks": checks,
        "open_pull_requests": open_pull_requests,
    }
    if args.json_output:
        output = args.json_output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    for item in checks:
        print(f"{str(item['status']).upper():7} {item['name']}: {item['detail']}")
    if open_pull_requests:
        print(f"INFO    open pull requests: {len(open_pull_requests)}")
        for item in open_pull_requests:
            print(f"        #{item['number']} {item['title']}")
    print(f"Submission readiness: {passed} passed, {failed} failed, {skipped} skipped")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
