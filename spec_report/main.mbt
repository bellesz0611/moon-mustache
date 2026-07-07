///|
fn main {
  let report = @src.format_spec_report_markdown(@src.run_all_spec_suites())
  println(report)
}
