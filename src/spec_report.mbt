///|
pub struct SpecCaseResult {
  suite_name : String
  case_name : String
  passed : Bool
  expected_output : String
  actual_output : String
  expected_errors : Array[String]
  actual_errors : Array[String]
}

///|
pub struct SpecSuiteResult {
  suite_name : String
  pass_count : Int
  total_count : Int
  case_results : Array[SpecCaseResult]
}

///|
fn same_string_arrays(left : Array[String], right : Array[String]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  let mut index = 0
  while index < left.length() {
    if left[index] != right[index] {
      return false
    }
    index = index + 1
  }
  true
}

///|
fn format_string_list(items : Array[String]) -> String {
  if items.length() == 0 {
    return "[]"
  }
  let builder = StringBuilder::new()
  builder.write_string("[")
  let mut index = 0
  while index < items.length() {
    if index > 0 {
      builder.write_string(", ")
    }
    builder.write_string(items[index])
    index = index + 1
  }
  builder.write_string("]")
  builder.to_string()
}

///|
pub fn run_spec_case(suite_name : String, case_ : SpecCase) -> SpecCaseResult {
  let result = render_json_bundle_checked(
    case_.template,
    case_.data_json,
    case_.partials_json,
  )
  let passed = result.output == case_.expected_output &&
    same_string_arrays(result.errors, case_.expected_errors)
  {
    suite_name,
    case_name: case_.name,
    passed,
    expected_output: case_.expected_output,
    actual_output: result.output,
    expected_errors: case_.expected_errors,
    actual_errors: result.errors,
  }
}

///|
pub fn run_spec_suite(suite : SpecSuite) -> SpecSuiteResult {
  let case_results : Array[SpecCaseResult] = []
  let mut pass_count = 0
  for case_ in suite.cases {
    let case_result = run_spec_case(suite.name, case_)
    if case_result.passed {
      pass_count = pass_count + 1
    }
    case_results.push(case_result)
  }
  {
    suite_name: suite.name,
    pass_count,
    total_count: suite.cases.length(),
    case_results,
  }
}

///|
pub fn run_all_spec_suites() -> Array[SpecSuiteResult] {
  let results : Array[SpecSuiteResult] = []
  for suite in all_spec_suites() {
    results.push(run_spec_suite(suite))
  }
  results
}

///|
pub fn suite_failed_count(result : SpecSuiteResult) -> Int {
  result.total_count - result.pass_count
}

///|
pub fn format_spec_suite_markdown(result : SpecSuiteResult) -> String {
  let builder = StringBuilder::new()
  builder.write_string("## ")
  builder.write_string(result.suite_name)
  builder.write_string("\n\n")
  builder.write_string("- passed: ")
  builder.write_string(result.pass_count.to_string())
  builder.write_string("/")
  builder.write_string(result.total_count.to_string())
  builder.write_string("\n")
  builder.write_string("- failed: ")
  builder.write_string(suite_failed_count(result).to_string())
  builder.write_string("\n\n")
  builder.write_string("| Case | Status |\n")
  builder.write_string("| --- | --- |\n")
  for case_result in result.case_results {
    builder.write_string("| ")
    builder.write_string(case_result.case_name)
    builder.write_string(" | ")
    builder.write_string(if case_result.passed { "pass" } else { "fail" })
    builder.write_string(" |\n")
  }
  builder.write_string("\n")
  for case_result in result.case_results {
    if !case_result.passed {
      builder.write_string("### Failure: ")
      builder.write_string(case_result.case_name)
      builder.write_string("\n\n")
      builder.write_string("- expected output: `")
      builder.write_string(case_result.expected_output)
      builder.write_string("`\n")
      builder.write_string("- actual output: `")
      builder.write_string(case_result.actual_output)
      builder.write_string("`\n")
      builder.write_string("- expected errors: `")
      builder.write_string(format_string_list(case_result.expected_errors))
      builder.write_string("`\n")
      builder.write_string("- actual errors: `")
      builder.write_string(format_string_list(case_result.actual_errors))
      builder.write_string("`\n\n")
    }
  }
  builder.to_string()
}

///|
pub fn format_spec_report_markdown(results : Array[SpecSuiteResult]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Moon Mustache Spec Compatibility Report\n\n")
  builder.write_string("| Suite | Passed | Total | Failed |\n")
  builder.write_string("| --- | ---: | ---: | ---: |\n")
  for result in results {
    builder.write_string("| ")
    builder.write_string(result.suite_name)
    builder.write_string(" | ")
    builder.write_string(result.pass_count.to_string())
    builder.write_string(" | ")
    builder.write_string(result.total_count.to_string())
    builder.write_string(" | ")
    builder.write_string(suite_failed_count(result).to_string())
    builder.write_string(" |\n")
  }
  builder.write_string("\n")
  for result in results {
    builder.write_string(format_spec_suite_markdown(result))
  }
  builder.to_string()
}
