test "official spec report keeps all CI-enabled fixtures green" {
  let results = run_official_spec_report()
  inspect(official_spec_total_failures(results).to_string(), content="0")
}

test "official spec report markdown has title and totals" {
  let report = format_official_spec_report_markdown(run_official_spec_report())
  inspect(report.contains("# Official mustache/spec Compatibility Report"), content="true")
  inspect(report.contains("- total cases: "), content="true")
}
