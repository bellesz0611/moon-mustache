from __future__ import annotations

import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from run_fault_injection import write_junit


def result(name: str, status: str, duration_ms: int) -> dict[str, object]:
    return {
        "name": name,
        "risk": f"risk for {name}",
        "file": "src/example.mbt",
        "test_file": "src/example_test.mbt",
        "test_filter": f"*{name}*",
        "status": status,
        "exit_code": 2 if status == "killed" else 0,
        "duration_ms": duration_ms,
        "test_summary": "Total tests: 1, passed: 0, failed: 1.",
        "output_tail": f"output for {name}",
    }


class FaultInjectionReportingTest(unittest.TestCase):
    def test_junit_distinguishes_killed_survived_and_invalid_mutants(self) -> None:
        results = [
            result("killed mutant", "killed", 100),
            result("survived mutant", "survived", 200),
            result("invalid mutant", "invalid", 300),
        ]
        with tempfile.TemporaryDirectory(prefix="fault-injection-report-") as directory:
            path = Path(directory) / "report.junit.xml"
            write_junit(path, results)
            root = ET.parse(path).getroot()

        self.assertEqual(root.attrib["tests"], "3")
        self.assertEqual(root.attrib["failures"], "1")
        self.assertEqual(root.attrib["errors"], "1")
        self.assertEqual(root.attrib["time"], "0.600")
        cases = root.findall("testcase")
        self.assertEqual(len(cases), 3)
        self.assertIsNone(cases[0].find("failure"))
        self.assertIsNone(cases[0].find("error"))
        self.assertEqual(cases[1].find("failure").attrib["type"], "survived")
        self.assertEqual(cases[2].find("error").attrib["type"], "invalid")
        self.assertIn("risk for killed mutant", cases[0].findtext("system-out", ""))


if __name__ == "__main__":
    unittest.main()
