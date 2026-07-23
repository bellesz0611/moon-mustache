from __future__ import annotations

import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from test_cli_integration import write_junit


class CliIntegrationReportingTest(unittest.TestCase):
    def test_junit_preserves_failure_and_unexecuted_checks(self) -> None:
        results = [
            {"name": "first check", "status": "passed", "duration_ms": 100},
            {
                "name": "second check",
                "status": "failed",
                "duration_ms": 200,
                "error": "diagnostic with <unsafe> content",
            },
        ]
        with tempfile.TemporaryDirectory(prefix="cli-integration-report-") as directory:
            path = Path(directory) / "cli.junit.xml"
            write_junit(path, results, ["first check", "second check", "third check"])
            root = ET.parse(path).getroot()

        self.assertEqual(root.attrib["tests"], "3")
        self.assertEqual(root.attrib["failures"], "1")
        self.assertEqual(root.attrib["skipped"], "1")
        self.assertEqual(root.attrib["time"], "0.300")
        cases = root.findall("testcase")
        self.assertEqual(len(cases), 3)
        self.assertIsNone(cases[0].find("failure"))
        self.assertIn("<unsafe>", cases[1].findtext("failure", ""))
        self.assertEqual(cases[2].find("skipped").text, "not run after an earlier failure")


if __name__ == "__main__":
    unittest.main()
