from __future__ import annotations

import unittest

from check_public_pii import labels_for_line


class PublicPiiTest(unittest.TestCase):
    def test_patterns_detect_common_identifier_shapes(self) -> None:
        phone = "138" + "1234" + "5678"
        bank_card = "4111" + "1111" + "1111" + "1111"
        identity = "110105" + "19491231" + "002X"
        self.assertIn("phone number", labels_for_line("contact " + phone))
        self.assertIn("bank-card-like number", labels_for_line(bank_card))
        self.assertIn("identity-card-like number", labels_for_line(identity))

    def test_patterns_ignore_short_or_non_numeric_text(self) -> None:
        for value in ("1234567890", "version 2026.07.23", "project-id-12345"):
            self.assertEqual(labels_for_line(value), set())


if __name__ == "__main__":
    unittest.main()
