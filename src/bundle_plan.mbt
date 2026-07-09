///|
pub struct BundlePlanFile {
  original_path : String
  normalized_path : String
  output_chars : Int
  output_lines : Int
  errors : Int
  missing_variables : Int
}

///|
pub struct BundlePlan {
  bundle_name : String
  files : Array[BundlePlanFile]
  validation_errors : Int
  validation_warnings : Int
}

///|
pub fn build_bundle_plan(
  bundle_name : String,
  render_result : BundleRenderResult,
  validation_result : BundleValidationResult,
) -> BundlePlan {
  let files : Array[BundlePlanFile] = []
  for file in render_result.files {
    let normalized_path = match
      validation_result.normalized_paths.get(file.path) {
      Some(value) => value
      None =>
        match normalize_bundle_path(file.path) {
          Ok(value) => value
          Err(_) => file.path
        }
    }
    files.push({
      original_path: file.path,
      normalized_path,
      output_chars: file.output.length(),
      output_lines: path_line_count(file.output),
      errors: file.errors.length(),
      missing_variables: file.missing_variables.length(),
    })
  }
  {
    bundle_name,
    files,
    validation_errors: validation_error_count(validation_result),
    validation_warnings: validation_warning_count(validation_result),
  }
}

///|
pub fn format_bundle_plan_markdown(plan : BundlePlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Bundle Generation Plan\n\n")
  builder.write_string("- bundle: ")
  builder.write_string(plan.bundle_name)
  builder.write_string("\n")
  builder.write_string("- files: ")
  builder.write_string(plan.files.length().to_string())
  builder.write_string("\n")
  builder.write_string("- validation errors: ")
  builder.write_string(plan.validation_errors.to_string())
  builder.write_string("\n")
  builder.write_string("- validation warnings: ")
  builder.write_string(plan.validation_warnings.to_string())
  builder.write_string("\n\n")
  builder.write_string(
    "| File | Normalized path | Chars | Lines | Errors | Missing variables |\n",
  )
  builder.write_string("| --- | --- | ---: | ---: | ---: | ---: |\n")
  for file in plan.files {
    builder.write_string("| ")
    builder.write_string(file.original_path)
    builder.write_string(" | ")
    builder.write_string(file.normalized_path)
    builder.write_string(" | ")
    builder.write_string(file.output_chars.to_string())
    builder.write_string(" | ")
    builder.write_string(file.output_lines.to_string())
    builder.write_string(" | ")
    builder.write_string(file.errors.to_string())
    builder.write_string(" | ")
    builder.write_string(file.missing_variables.to_string())
    builder.write_string(" |\n")
  }
  builder.to_string()
}
