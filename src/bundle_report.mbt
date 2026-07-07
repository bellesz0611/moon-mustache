///|
pub fn format_bundle_result_markdown(
  bundle_name : String,
  result : BundleRenderResult,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Bundle Render Report\n\n")
  builder.write_string("- bundle: ")
  builder.write_string(bundle_name)
  builder.write_string("\n")
  builder.write_string("- files: ")
  builder.write_string(result.files.length().to_string())
  builder.write_string("\n")
  builder.write_string("- errors: ")
  builder.write_string(result.errors.length().to_string())
  builder.write_string("\n")
  builder.write_string("- missing variables: ")
  builder.write_string(result.missing_variables.length().to_string())
  builder.write_string("\n\n")
  builder.write_string("| File | Output chars | Errors | Missing variables |\n")
  builder.write_string("| --- | ---: | ---: | ---: |\n")
  for file in result.files {
    builder.write_string("| ")
    builder.write_string(file.path)
    builder.write_string(" | ")
    builder.write_string(file.output.length().to_string())
    builder.write_string(" | ")
    builder.write_string(file.errors.length().to_string())
    builder.write_string(" | ")
    builder.write_string(file.missing_variables.length().to_string())
    builder.write_string(" |\n")
  }
  builder.write_string("\n")
  if result.errors.length() > 0 {
    builder.write_string("## Errors\n\n")
    for error in result.errors {
      builder.write_string("- ")
      builder.write_string(error)
      builder.write_string("\n")
    }
    builder.write_string("\n")
  }
  if result.missing_variables.length() > 0 {
    builder.write_string("## Missing Variables\n\n")
    for name in result.missing_variables {
      builder.write_string("- ")
      builder.write_string(name)
      builder.write_string("\n")
    }
    builder.write_string("\n")
  }
  for file in result.files {
    builder.write_string("## ")
    builder.write_string(file.path)
    builder.write_string("\n\n```text\n")
    builder.write_string(file.output)
    if !file.output.has_suffix("\n") {
      builder.write_string("\n")
    }
    builder.write_string("```\n\n")
  }
  builder.to_string()
}

///|
fn escape_json_string(input : String) -> String {
  let builder = StringBuilder::new()
  for char in input {
    match char {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      _ => builder.write_char(char)
    }
  }
  builder.to_string()
}

///|
fn string_list_json(items : Array[String]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("[")
  let mut index = 0
  while index < items.length() {
    if index > 0 {
      builder.write_string(",")
    }
    builder.write_string("\"")
    builder.write_string(escape_json_string(items[index]))
    builder.write_string("\"")
    index = index + 1
  }
  builder.write_string("]")
  builder.to_string()
}

///|
pub fn format_bundle_result_json(
  bundle_name : String,
  result : BundleRenderResult,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"bundle\":\"")
  builder.write_string(escape_json_string(bundle_name))
  builder.write_string("\",")
  builder.write_string("\"errors\":")
  builder.write_string(string_list_json(result.errors))
  builder.write_string(",")
  builder.write_string("\"missing_variables\":")
  builder.write_string(string_list_json(result.missing_variables))
  builder.write_string(",")
  builder.write_string("\"files\":[")
  let mut index = 0
  while index < result.files.length() {
    if index > 0 {
      builder.write_string(",")
    }
    let file = result.files[index]
    builder.write_string("{")
    builder.write_string("\"path\":\"")
    builder.write_string(escape_json_string(file.path))
    builder.write_string("\",")
    builder.write_string("\"output\":\"")
    builder.write_string(escape_json_string(file.output))
    builder.write_string("\",")
    builder.write_string("\"errors\":")
    builder.write_string(string_list_json(file.errors))
    builder.write_string(",")
    builder.write_string("\"missing_variables\":")
    builder.write_string(string_list_json(file.missing_variables))
    builder.write_string("}")
    index = index + 1
  }
  builder.write_string("]}")
  builder.to_string()
}
