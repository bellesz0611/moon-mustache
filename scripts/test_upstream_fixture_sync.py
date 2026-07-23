from __future__ import annotations

import unittest

from check_upstream_fixture_sync import build_report


class UpstreamFixtureSyncTest(unittest.TestCase):
    def setUp(self) -> None:
        self.manifest = {
            "upstream": {
                "repository": "https://github.com/mustache/spec",
                "commit": "pinned-commit",
            }
        }

    def test_same_commit_is_current(self) -> None:
        report = build_report(self.manifest, {"commit": "pinned-commit", "commit_date": "2026-07-23T00:00:00Z"})
        self.assertEqual(report["status"], "up_to_date")
        self.assertIn("No fixture regeneration", report["action"])

    def test_different_commit_is_reported_without_auto_mutation(self) -> None:
        report = build_report(self.manifest, {"commit": "newer-commit", "commit_date": ""})
        self.assertEqual(report["status"], "newer_available")
        self.assertIn("Review upstream changes", report["action"])


if __name__ == "__main__":
    unittest.main()
