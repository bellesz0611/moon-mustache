from __future__ import annotations

import unittest

from check_benchmark_contract import EXPECTED_WORKLOADS, validate_payload


def entry(name: str) -> dict[str, object]:
    return {
        "name": name,
        "min": 1.0,
        "max": 3.0,
        "mean": 2.0,
        "median": 2.0,
        "std_dev_pct": 4.0,
        "runs": 10,
        "batch_size": 100,
    }


class BenchmarkContractTest(unittest.TestCase):
    def test_expected_workload_set_and_numeric_contract_pass(self) -> None:
        report = validate_payload([entry(name) for name in EXPECTED_WORKLOADS])
        self.assertTrue(report["passed"])
        self.assertEqual(report["errors"], [])

    def test_duplicate_missing_and_invalid_metrics_fail(self) -> None:
        payload = [entry(name) for name in EXPECTED_WORKLOADS[:-1]]
        invalid = entry(EXPECTED_WORKLOADS[0])
        invalid["mean"] = -1.0
        invalid["runs"] = 0
        payload.append(invalid)
        report = validate_payload(payload)
        self.assertFalse(report["passed"])
        joined = "\n".join(report["errors"])
        self.assertIn("duplicate workloads", joined)
        self.assertIn("missing workloads", joined)
        self.assertIn("mean must be finite and non-negative", joined)
        self.assertIn("runs must be a positive integer", joined)


if __name__ == "__main__":
    unittest.main()
