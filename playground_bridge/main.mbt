fn first_value(args : Array[String], name : String) -> String? {
  let mut index = 0
  while index < args.length() {
    if args[index] == name && index + 1 < args.length() {
      return Some(args[index + 1])
    }
    index = index + 1
  }
  None
}

fn flag_enabled(args : Array[String], name : String) -> Bool {
  args.any(value => value == name)
}

fn decode_base64_text(encoded : String, label : String) -> Result[String, String] {
  let decoded = @base64.decode(encoded) catch {
    _ => return Err("invalid Base64 " + label)
  }
  let text = @utf8.decode(decoded) catch {
    _ => return Err("invalid UTF-8 " + label)
  }
  Ok(text)
}

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

fn render_response_json(
  output : String,
  errors : Array[String],
  missing_variables : Array[String],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{")
  builder.write_string("\"output\":\"")
  builder.write_string(escape_json_string(output))
  builder.write_string("\",")
  builder.write_string("\"errors\":")
  builder.write_string(string_list_json(errors))
  builder.write_string(",")
  builder.write_string("\"missing_variables\":")
  builder.write_string(string_list_json(missing_variables))
  builder.write_string("}")
  builder.to_string()
}

fn error_response_json(message : String) -> String {
  render_response_json("", [message], [])
}

fn effective_argv() -> Array[String] {
  let args = @env.args()
  if args.length() > 2 && args[1].strip_suffix(".js") is Some(_) {
    args[2:].to_owned()
  } else if args.length() > 1 {
    args[1:].to_owned()
  } else {
    []
  }
}

fn main {
  let args = effective_argv()
  let template_base64 = match first_value(args, "--template-base64") {
    Some(value) => value
    None => {
      println(error_response_json("missing required argument: --template-base64"))
      return
    }
  }
  let context_base64 = match first_value(args, "--context-base64") {
    Some(value) => value
    None => {
      println(error_response_json("missing required argument: --context-base64"))
      return
    }
  }
  let partials_base64 = match first_value(args, "--partials-base64") {
    Some(value) => value
    None => {
      println(error_response_json("missing required argument: --partials-base64"))
      return
    }
  }

  let template = match decode_base64_text(template_base64, "template") {
    Ok(value) => value
    Err(message) => {
      println(error_response_json(message))
      return
    }
  }
  let context_json = match decode_base64_text(context_base64, "context JSON") {
    Ok(value) => value
    Err(message) => {
      println(error_response_json(message))
      return
    }
  }
  let partials_json = match decode_base64_text(partials_base64, "partials JSON") {
    Ok(value) => value
    Err(message) => {
      println(error_response_json(message))
      return
    }
  }

  let partials = match @src.parse_json_partials_checked(partials_json) {
    Ok(value) => value
    Err(message) => {
      println(error_response_json(message))
      return
    }
  }

  let render_options =
    if flag_enabled(args, "--strict-missing") {
      @src.RenderOptions::strict()
    } else {
      @src.RenderOptions::default()
    }

  let result = @src.render_json_checked_with_options(
    template,
    context_json,
    partials,
    render_options,
  )
  println(render_response_json(result.output, result.errors, result.missing_variables))
}
