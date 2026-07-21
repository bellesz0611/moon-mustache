///|
test "spec report preserves output and error mismatches" {
  let wrong_output = spec_case(
    "wrong output", "Hello {{name}}", "{\"name\":\"MoonBit\"}", "Hello Other",
  )
  let wrong_error_count = spec_case(
    "wrong error count",
    "{{#open}}",
    "{}",
    "",
    expected_errors=[],
  )
  let wrong_error_content = spec_case(
    "wrong error content",
    "{{#open}}",
    "{}",
    "",
    expected_errors=["different diagnostic"],
  )
  let suite : SpecSuite = {
    name: "failure-contract",
    cases: [wrong_output, wrong_error_count, wrong_error_content],
  }
  let result = run_spec_suite(suite)
  inspect(result.pass_count, content="0")
  inspect(result.total_count, content="3")
  inspect(suite_failed_count(result), content="3")

  let markdown = format_spec_suite_markdown(result)
  inspect(markdown.contains("### Failure: wrong output"), content="true")
  inspect(markdown.contains("expected output"), content="true")
  inspect(markdown.contains("actual errors"), content="true")
  inspect(markdown.contains("[different diagnostic]"), content="true")

  let full_report = format_spec_report_markdown([result])
  inspect(full_report.contains("failure-contract | 0 | 3 | 3"), content="true")
}

///|
test "lint report formats clean and warning-only states" {
  let clean : LintReport = {
    diagnostics: [],
    data_names: [],
    partial_names: [],
  }
  inspect(lint_error_count(clean), content="0")
  inspect(lint_warning_count(clean), content="0")
  inspect(format_lint_report(clean).contains("status: clean"), content="true")

  let warning = make_diagnostic(
    "source",
    "MST-TEST-WARNING",
    DiagnosticWarning,
    "warning branch",
    0,
    6,
    source_name="warning.mbt",
  )
  let warning_report : LintReport = {
    diagnostics: [warning],
    data_names: [],
    partial_names: [],
  }
  inspect(lint_error_count(warning_report), content="0")
  inspect(lint_warning_count(warning_report), content="1")
  inspect(lint_has_errors(warning_report), content="false")
  inspect(
    format_lint_report(warning_report).contains("MST-TEST-WARNING"),
    content="true",
  )
}

///|
test "Token is_tag separates text from syntax tokens" {
  inspect(Token::new(Text, "plain", 0, 5).is_tag(), content="false")
  inspect(Token::new(Variable, "name", 0, 8).is_tag(), content="true")
}
