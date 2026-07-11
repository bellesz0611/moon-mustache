from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SPECS_DIR = ROOT / "third_party" / "mustache-spec" / "specs"
OUTPUT = ROOT / "src" / "official_spec_fixtures.mbt"

SUITES = [
    "comments",
    "delimiters",
    "interpolation",
    "inverted",
    "partials",
    "sections",
    "~dynamic-names",
    "~inheritance",
    "~lambdas",
]

SKIP_REASONS = {}


def mbt_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def generate() -> None:
    lines: list[str] = []
    lines.append("pub struct OfficialSpecCase {")
    lines.append("  suite_name : String")
    lines.append("  case_name : String")
    lines.append("  description : String")
    lines.append("  template : String")
    lines.append("  data_json : String")
    lines.append("  partials_json : String")
    lines.append("  expected_output : String")
    lines.append("  run_in_ci : Bool")
    lines.append("  skip_reason : String?")
    lines.append("}")
    lines.append("")
    lines.append("pub fn official_spec_cases() -> Array[OfficialSpecCase] {")
    lines.append("  [")
    for suite in SUITES:
        payload = json.loads((SPECS_DIR / f"{suite}.json").read_text(encoding="utf-8"))
        for test in payload["tests"]:
            key = (suite, test["name"])
            skip_reason = SKIP_REASONS.get(key)
            partials = test.get("partials", {})
            lines.append("    {")
            lines.append(f"      suite_name: {mbt_string(suite)},")
            lines.append(f"      case_name: {mbt_string(test['name'])},")
            lines.append(f"      description: {mbt_string(test.get('desc', ''))},")
            lines.append(f"      template: {mbt_string(test['template'])},")
            lines.append(f"      data_json: {mbt_string(json.dumps(test.get('data', {}), ensure_ascii=False))},")
            lines.append(f"      partials_json: {mbt_string(json.dumps(partials, ensure_ascii=False))},")
            lines.append(f"      expected_output: {mbt_string(test['expected'])},")
            lines.append(f"      run_in_ci: {'false' if skip_reason else 'true'},")
            if skip_reason:
                lines.append(f"      skip_reason: Some({mbt_string(skip_reason)}),")
            else:
                lines.append("      skip_reason: None,")
            lines.append("    },")
    lines.append("  ]")
    lines.append("}")
    OUTPUT.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    generate()
