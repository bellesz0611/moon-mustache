///|
fn assert_spec_suite(suite : SpecSuite) -> Unit raise InspectError {
  let result = run_spec_suite(suite)
  inspect(result.pass_count.to_string(), content=result.total_count.to_string())
  inspect(suite_failed_count(result).to_string(), content="0")
}

///|
test "spec suite: interpolation" {
  assert_spec_suite(interpolation_spec_suite())
}

///|
test "spec suite: comments" {
  assert_spec_suite(comment_spec_suite())
}

///|
test "spec suite: sections" {
  assert_spec_suite(section_spec_suite())
}

///|
test "spec suite: inverted" {
  assert_spec_suite(inverted_spec_suite())
}

///|
test "spec suite: partials" {
  assert_spec_suite(partial_spec_suite())
}

///|
test "spec suite: delimiters" {
  assert_spec_suite(delimiter_spec_suite())
}

///|
test "spec suite: standalone" {
  assert_spec_suite(standalone_spec_suite())
}

///|
test "spec suite: whitespace" {
  assert_spec_suite(whitespace_spec_suite())
}

///|
test "spec suite: diagnostics" {
  assert_spec_suite(diagnostics_spec_suite())
}

///|
test "spec report markdown contains suite headers" {
  let report = format_spec_report_markdown(run_all_spec_suites())
  inspect(
    report.contains("Moon Mustache Spec Compatibility Report"),
    content="true",
  )
  inspect(report.contains("| interpolation |"), content="true")
  inspect(report.contains("## partials"), content="true")
  inspect(report.contains("## diagnostics"), content="true")
}
