test "scenario report stays green" {
  let results = run_scenario_report()
  inspect(results.length(), content="9")
  let mut passed = 0
  for result in results {
    if result.passed {
      passed = passed + 1
    }
  }
  inspect(passed.to_string(), content="9")
}

test "scenario report markdown contains headers" {
  let report = format_scenario_report_markdown(run_scenario_report())
  inspect(report.contains("# Moon Mustache Scenario Report"), content="true")
  inspect(report.contains("| manifest_profile | pass |"), content="true")
  inspect(report.contains("| bundle_validation_plan | pass |"), content="true")
}
