///|
pub fn parse_assignment(entry : String) -> (String, String)? {
  match entry.split_once("=") {
    Some((name, value)) => Some((name.to_owned(), value.to_owned()))
    None => None
  }
}

///|
pub fn unique_diagnostics(errors : Array[String]) -> Array[String] {
  let unique : Array[String] = []
  let seen : Map[String, Bool] = {}
  for error in errors {
    if !seen.get_or_default(error, false) {
      seen[error] = true
      unique.push(error)
    }
  }
  unique
}

///|
pub fn diagnostic_tip(message : String) -> String? {
  if message.contains("invalid --var assignment") {
    Some(
      "Use --var key=value. Dotted keys such as user.name=Alice are supported.",
    )
  } else if message.contains("invalid --partial assignment") {
    Some(
      "Use --partial name=template, or load multiple partials with --partials-json-file.",
    )
  } else if message.contains("missing partial:") {
    Some(
      "Add the partial inline with --partial name=..., or load a JSON partial map with --partials-json-file.",
    )
  } else if message.contains("missing variable:") {
    Some(
      "Provide the value through --var, --json, --json-file, or the selected bundle profile context.",
    )
  } else if message.contains("invalid JSON context") {
    Some(
      "Check shell quoting first. On PowerShell, --json-base64 is often the easiest way to pass JSON safely.",
    )
  } else if message.contains("invalid partials JSON") {
    Some(
      "The partials file must be a JSON object that maps partial names to template strings.",
    )
  } else if message.contains("failed to read template file") ||
    message.contains("failed to read JSON context file") ||
    message.contains("failed to read partials file") ||
    message.contains("failed to read bundle manifest file") {
    Some(
      "Double-check the path, and use --target js for file-backed CLI flows.",
    )
  } else if message.contains(
      "file IO is only supported when running the CLI with --target js",
    ) {
    Some(
      "Re-run the command as moon run --target js cli ... when reading or writing files.",
    )
  } else if message.contains("invalid bundle manifest:") {
    Some(
      "Validate the manifest shape first, or print the sample manifest with --print-sample-manifest.",
    )
  } else if message.contains("unsupported bundle report format") {
    Some("Use --bundle-report-format markdown or --bundle-report-format json.")
  } else if message.contains("parent traversal") ||
    message.contains("invalid-output-path") {
    Some(
      "Bundle output paths must stay inside the generated project tree and cannot use parent traversal segments.",
    )
  } else if message.contains("unterminated section:") {
    Some(
      "Every {{#name}} or {{^name}} block needs a matching closing tag such as {{/name}}.",
    )
  } else if message.contains("partial depth limit exceeded:") {
    Some(
      "This usually means recursive partial expansion. Check whether a partial includes itself directly or indirectly.",
    )
  } else {
    None
  }
}

///|
pub fn default_template() -> String {
  "Project {{name}} builds a {{role}}.\n{{> footer}}"
}

///|
pub fn merge_partial_maps(
  base : Map[String, String],
  incoming : Map[String, String],
) -> Map[String, String] {
  let merged : Map[String, String] = {}
  for name, template in base {
    merged[name] = template
  }
  for name, template in incoming {
    merged[name] = template
  }
  merged
}

///|
pub fn join_output_path(root : String, relative : String) -> String {
  if root == "" {
    relative
  } else {
    root + "/" + relative
  }
}

///|
pub fn build_bundle_report_output(
  format : String,
  bundle_name : String,
  result : @src.BundleRenderResult,
) -> (String, String)? {
  if format == "json" {
    Some(("json", @src.format_bundle_result_json(bundle_name, result)))
  } else if format == "markdown" {
    Some(("markdown", @src.format_bundle_result_markdown(bundle_name, result)))
  } else {
    None
  }
}

///|
pub fn build_bundle_plan_output(
  bundle_name : String,
  render_result : @src.BundleRenderResult,
  validation_result : @src.BundleValidationResult,
) -> String {
  @src.format_bundle_plan_markdown(
    @src.build_bundle_plan(bundle_name, render_result, validation_result),
  )
}

///|
pub fn validation_issue_diagnostic(
  issue : @src.BundleValidationIssue,
) -> String {
  let severity = match issue.severity {
    Error => "error"
    Warning => "warning"
  }
  "bundle " +
  severity +
  " [" +
  issue.code +
  "] " +
  issue.target +
  ": " +
  issue.message
}

///|
pub fn should_block_single_template(
  strict : Bool,
  fatal_error_count : Int,
  missing_variable_count : Int,
) -> Bool {
  fatal_error_count > 0 || (strict && missing_variable_count > 0)
}

///|
pub fn should_block_bundle(
  strict : Bool,
  render_error_count : Int,
  validation_has_errors : Bool,
) -> Bool {
  strict || render_error_count > 0 || validation_has_errors
}
