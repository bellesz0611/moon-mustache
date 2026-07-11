///|
fn escape_json_string(input : String) -> String {
  let builder = StringBuilder::new()
  for char in input {
    match char {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\b' => builder.write_string("\\b")
      '\f' => builder.write_string("\\f")
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
  for index, item in items {
    if index > 0 {
      builder.write_string(",")
    }
    builder.write_string("\"")
    builder.write_string(escape_json_string(item))
    builder.write_string("\"")
  }
  builder.write_string("]")
  builder.to_string()
}

///|
fn response_json(
  output : String,
  errors : Array[String],
  missing_variables : Array[String],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{\"output\":\"")
  builder.write_string(escape_json_string(output))
  builder.write_string("\",\"errors\":")
  builder.write_string(string_list_json(errors))
  builder.write_string(",\"missing_variables\":")
  builder.write_string(string_list_json(missing_variables))
  builder.write_string("}")
  builder.to_string()
}

///|
pub fn render_json_bridge(
  template : String,
  context_json : String,
  partials_json : String,
  strict_missing : Bool,
) -> String {
  let partials = match @src.parse_json_partials_checked(partials_json) {
    Ok(value) => value
    Err(message) => return response_json("", [message], [])
  }
  let options = if strict_missing {
    @src.RenderOptions::strict()
  } else {
    @src.RenderOptions::default()
  }
  let result = @src.render_json_checked_with_options(
    template, context_json, partials, options,
  )
  response_json(result.output, result.errors, result.missing_variables)
}
