///|
pub enum OfficialSpecStatus {
  Passed
  Failed
  Skipped
}

///|
pub struct OfficialSpecCaseResult {
  suite_name : String
  case_name : String
  status : OfficialSpecStatus
  expected_output : String
  actual_output : String
  skip_reason : String?
}

///|
pub struct OfficialSpecSuiteResult {
  suite_name : String
  passed : Int
  failed : Int
  skipped : Int
  cases : Array[OfficialSpecCaseResult]
}

///|
fn parse_official_partials(input : String) -> Map[String, String] {
  let parsed = parse_json_partials_checked(input)
  match parsed {
    Ok(partials) => partials
    Err(_) => {}
  }
}

///|
fn official_lambda_value(case_name : String) -> Value {
  match case_name {
    "Interpolation" => Value::interpolation_lambda(fn() { "world" })
    "Interpolation - Expansion" =>
      Value::interpolation_lambda(fn() { "{{planet}}" })
    "Interpolation - Alternate Delimiters" =>
      Value::interpolation_lambda(fn() { "|planet| => {{planet}}" })
    "Interpolation - Multiple Calls" => {
      let calls = [0]
      Value::interpolation_lambda(fn() {
        calls[0] = calls[0] + 1
        calls[0].to_string()
      })
    }
    "Escaping" => Value::interpolation_lambda(fn() { ">" })
    "Section" =>
      Value::section_lambda(fn(text) {
        if text == "{{x}}" {
          "yes"
        } else {
          "no"
        }
      })
    "Section - Expansion" =>
      Value::section_lambda(fn(text) { text + "{{planet}}" + text })
    "Section - Alternate Delimiters" =>
      Value::section_lambda(fn(text) { text + "{{planet}} => |planet|" + text })
    "Section - Multiple Calls" =>
      Value::section_lambda(fn(text) { "__" + text + "__" })
    "Inverted Section" => Value::section_lambda(fn(_text) { "false" })
    _ => Value::interpolation_lambda(fn() { "" })
  }
}

///|
fn adapt_official_context(case_ : OfficialSpecCase, context : Value) -> Value {
  if case_.suite_name != "~lambdas" {
    return context
  }
  match context {
    ObjectValue(entries) => {
      entries["lambda"] = official_lambda_value(case_.case_name)
      Value::object(entries)
    }
    _ => context
  }
}

///|
fn official_case_result_for_skip(
  case_ : OfficialSpecCase,
  reason : String,
) -> OfficialSpecCaseResult {
  {
    suite_name: case_.suite_name,
    case_name: case_.case_name,
    status: Skipped,
    expected_output: case_.expected_output,
    actual_output: "",
    skip_reason: Some(reason),
  }
}

///|
fn run_official_spec_case(case_ : OfficialSpecCase) -> OfficialSpecCaseResult {
  match case_.skip_reason {
    Some(reason) => official_case_result_for_skip(case_, reason)
    None => {
      let context = parse_json_context(case_.data_json) catch {
        _ =>
          return {
            suite_name: case_.suite_name,
            case_name: case_.case_name,
            status: Failed,
            expected_output: case_.expected_output,
            actual_output: "<invalid context json>",
            skip_reason: None,
          }
      }
      let context = adapt_official_context(case_, context)
      let actual = render_with_partials(
        case_.template,
        context,
        parse_official_partials(case_.partials_json),
      )
      {
        suite_name: case_.suite_name,
        case_name: case_.case_name,
        status: if actual == case_.expected_output {
          Passed
        } else {
          Failed
        },
        expected_output: case_.expected_output,
        actual_output: actual,
        skip_reason: None,
      }
    }
  }
}

///|
fn official_suite_names() -> Array[String] {
  let names : Array[String] = []
  for case_ in official_spec_cases() {
    let mut seen = false
    for existing in names {
      if existing == case_.suite_name {
        seen = true
      }
    }
    if !seen {
      names.push(case_.suite_name)
    }
  }
  names
}

///|
pub fn run_official_spec_report() -> Array[OfficialSpecSuiteResult] {
  let results : Array[OfficialSpecSuiteResult] = []
  for suite_name in official_suite_names() {
    let cases : Array[OfficialSpecCaseResult] = []
    let mut passed = 0
    let mut failed = 0
    let mut skipped = 0
    for case_ in official_spec_cases() {
      if case_.suite_name != suite_name {
        continue
      }
      let result = run_official_spec_case(case_)
      match result.status {
        Passed => passed = passed + 1
        Failed => failed = failed + 1
        Skipped => skipped = skipped + 1
      }
      cases.push(result)
    }
    results.push({ suite_name, passed, failed, skipped, cases })
  }
  results
}

///|
pub fn official_spec_total_cases(
  results : Array[OfficialSpecSuiteResult],
) -> Int {
  let mut total = 0
  for result in results {
    total = total + result.cases.length()
  }
  total
}

///|
pub fn official_spec_total_failures(
  results : Array[OfficialSpecSuiteResult],
) -> Int {
  let mut total = 0
  for result in results {
    total = total + result.failed
  }
  total
}

///|
pub fn official_spec_total_skips(
  results : Array[OfficialSpecSuiteResult],
) -> Int {
  let mut total = 0
  for result in results {
    total = total + result.skipped
  }
  total
}

///|
pub fn format_official_spec_report_markdown(
  results : Array[OfficialSpecSuiteResult],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Official mustache/spec Compatibility Report\n\n")
  builder.write_string("| Suite | Passed | Failed | Skipped |\n")
  builder.write_string("| --- | ---: | ---: | ---: |\n")
  for result in results {
    builder.write_string("| ")
    builder.write_string(result.suite_name)
    builder.write_string(" | ")
    builder.write_string(result.passed.to_string())
    builder.write_string(" | ")
    builder.write_string(result.failed.to_string())
    builder.write_string(" | ")
    builder.write_string(result.skipped.to_string())
    builder.write_string(" |\n")
  }
  builder.write_string("\n")
  builder.write_string("- total cases: ")
  builder.write_string(official_spec_total_cases(results).to_string())
  builder.write_string("\n")
  builder.write_string("- total failures: ")
  builder.write_string(official_spec_total_failures(results).to_string())
  builder.write_string("\n")
  builder.write_string("- total skips: ")
  builder.write_string(official_spec_total_skips(results).to_string())
  builder.write_string("\n\n")
  for result in results {
    builder.write_string("## ")
    builder.write_string(result.suite_name)
    builder.write_string("\n\n")
    builder.write_string("| Case | Status |\n")
    builder.write_string("| --- | --- |\n")
    for case_result in result.cases {
      let status = match case_result.status {
        Passed => "pass"
        Failed => "fail"
        Skipped => "skip"
      }
      builder.write_string("| ")
      builder.write_string(case_result.case_name)
      builder.write_string(" | ")
      builder.write_string(status)
      builder.write_string(" |\n")
    }
    builder.write_string("\n")
    for case_result in result.cases {
      match case_result.status {
        Failed => {
          builder.write_string("### Failure: ")
          builder.write_string(case_result.case_name)
          builder.write_string("\n\n")
          builder.write_string("- expected: `")
          builder.write_string(case_result.expected_output)
          builder.write_string("`\n")
          builder.write_string("- actual: `")
          builder.write_string(case_result.actual_output)
          builder.write_string("`\n\n")
        }
        Skipped =>
          match case_result.skip_reason {
            Some(reason) => {
              builder.write_string("### Skipped: ")
              builder.write_string(case_result.case_name)
              builder.write_string("\n\n- reason: ")
              builder.write_string(reason)
              builder.write_string("\n\n")
            }
            None => ()
          }
        Passed => ()
      }
    }
  }
  builder.to_string()
}
