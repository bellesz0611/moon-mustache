///|
pub enum ValidationSeverity {
  Warning
  Error
}

///|
pub struct BundleValidationIssue {
  severity : ValidationSeverity
  code : String
  target : String
  message : String
}

///|
pub struct BundleValidationResult {
  normalized_paths : Map[String, String]
  issues : Array[BundleValidationIssue]
}

///|
fn add_validation_issue(
  issues : Array[BundleValidationIssue],
  severity : ValidationSeverity,
  code : String,
  target : String,
  message : String,
) -> Unit {
  issues.push({ severity, code, target, message })
}

///|
pub fn validate_template_bundle(
  bundle : TemplateBundle,
) -> BundleValidationResult {
  let normalized_paths : Map[String, String] = {}
  let normalized_index : Map[String, String] = {}
  let issues : Array[BundleValidationIssue] = []
  for file in bundle.files {
    if file.template == "" {
      add_validation_issue(
        issues,
        Warning,
        "empty-template",
        file.path,
        "template content is empty",
      )
    }
    match normalize_bundle_path(file.path) {
      Ok(normalized) => {
        normalized_paths[file.path] = normalized
        match normalized_index.get(normalized) {
          Some(existing) =>
            add_validation_issue(
              issues,
              Error,
              "duplicate-output-path",
              file.path,
              "normalized path conflicts with `" + existing + "`",
            )
          None => normalized_index[normalized] = file.path
        }
      }
      Err(message) =>
        add_validation_issue(
          issues,
          Error,
          "invalid-output-path",
          file.path,
          message,
        )
    }
  }
  for name, template in bundle.partials {
    if name == "" {
      add_validation_issue(
        issues,
        Error,
        "empty-partial-name",
        "<partial>",
        "partial names must not be empty",
      )
    }
    if template == "" {
      add_validation_issue(
        issues,
        Warning,
        "empty-partial-template",
        name,
        "partial template is empty",
      )
    }
  }
  { normalized_paths, issues }
}

///|
pub fn validate_bundle_manifest(
  manifest : BundleManifest,
) -> BundleValidationResult {
  let result = validate_template_bundle(manifest.bundle)
  let issues = result.issues.copy()
  if manifest.name == "" {
    add_validation_issue(
      issues,
      Warning,
      "empty-manifest-name",
      "<manifest>",
      "manifest name is empty",
    )
  }
  for profile_name, profile in manifest.profiles {
    if profile_name == "" {
      add_validation_issue(
        issues,
        Error,
        "empty-profile-name",
        "<profiles>",
        "profile names must not be empty",
      )
    }
    for partial_name, template in profile.partials {
      if partial_name == "" {
        add_validation_issue(
          issues,
          Error,
          "empty-profile-partial-name",
          profile_name,
          "profile partial names must not be empty",
        )
      }
      if template == "" {
        add_validation_issue(
          issues,
          Warning,
          "empty-profile-partial-template",
          profile_name + ":" + partial_name,
          "profile partial template is empty",
        )
      }
    }
  }
  { normalized_paths: result.normalized_paths, issues }
}

///|
pub fn validation_error_count(result : BundleValidationResult) -> Int {
  let mut count = 0
  for issue in result.issues {
    match issue.severity {
      Error => count = count + 1
      Warning => ()
    }
  }
  count
}

///|
pub fn validation_warning_count(result : BundleValidationResult) -> Int {
  let mut count = 0
  for issue in result.issues {
    match issue.severity {
      Warning => count = count + 1
      Error => ()
    }
  }
  count
}

///|
pub fn validation_has_errors(result : BundleValidationResult) -> Bool {
  validation_error_count(result) > 0
}

///|
pub fn format_validation_report_markdown(
  bundle_name : String,
  result : BundleValidationResult,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Bundle Validation Report\n\n")
  builder.write_string("- bundle: ")
  builder.write_string(bundle_name)
  builder.write_string("\n")
  builder.write_string("- errors: ")
  builder.write_string(validation_error_count(result).to_string())
  builder.write_string("\n")
  builder.write_string("- warnings: ")
  builder.write_string(validation_warning_count(result).to_string())
  builder.write_string("\n\n")
  builder.write_string("| Severity | Code | Target | Message |\n")
  builder.write_string("| --- | --- | --- | --- |\n")
  for issue in result.issues {
    let severity = match issue.severity {
      Error => "error"
      Warning => "warning"
    }
    builder.write_string("| ")
    builder.write_string(severity)
    builder.write_string(" | ")
    builder.write_string(issue.code)
    builder.write_string(" | ")
    builder.write_string(issue.target)
    builder.write_string(" | ")
    builder.write_string(issue.message)
    builder.write_string(" |\n")
  }
  if result.issues.length() == 0 {
    builder.write_string("| ok | clean | - | no validation issues |\n")
  }
  builder.to_string()
}
