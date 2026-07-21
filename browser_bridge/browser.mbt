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
fn generated_files_json(items : Array[@src.GeneratedFile]) -> String {
  let builder = StringBuilder::new()
  builder.write_string("[")
  for index, item in items {
    if index > 0 {
      builder.write_string(",")
    }
    builder.write_string("{\"path\":\"")
    builder.write_string(escape_json_string(item.path))
    builder.write_string("\",\"output\":\"")
    builder.write_string(escape_json_string(item.output))
    builder.write_string("\",\"errors\":")
    builder.write_string(string_list_json(item.errors))
    builder.write_string(",\"missing_variables\":")
    builder.write_string(string_list_json(item.missing_variables))
    builder.write_string("}")
  }
  builder.write_string("]")
  builder.to_string()
}

///|
fn bundle_response_json(result : @src.BundleRenderResult) -> String {
  let builder = StringBuilder::new()
  builder.write_string("{\"files\":")
  builder.write_string(generated_files_json(result.files))
  builder.write_string(",\"errors\":")
  builder.write_string(string_list_json(result.errors))
  builder.write_string(",\"missing_variables\":")
  builder.write_string(string_list_json(result.missing_variables))
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

///|
pub fn generate_starter_bridge(
  context_json : String,
  strict_missing : Bool,
) -> String {
  let bundle = @src.TemplateBundle::new(
    [
      @src.TemplateFile::new(
        "moon.mod", "name = \"{{package}}\"\n\nversion = \"0.1.0\"\n\nreadme = \"README.md\"\n\nlicense = \"MIT\"\n",
      ),
      @src.TemplateFile::new(
        "README.md", "# {{display_name}}\n\n{{description}}\n\n```bash\nmoon run src\n```\n",
      ),
      @src.TemplateFile::new(
        "src/main.mbt", "///|\nfn main {\n  println(\"Hello from {{display_name}}!\")\n}\n",
      ),
      @src.TemplateFile::new("src/moon.pkg", ""),
      @src.TemplateFile::new(
        ".github/workflows/ci.yml", "name: check\n\non: [push, pull_request]\n\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v5\n      - uses: moonbitlang/setup-moonbit@v1\n      - run: moon test --deny-warn\n",
      ),
    ],
    {},
  )
  let options = if strict_missing {
    @src.RenderOptions::strict()
  } else {
    @src.RenderOptions::default()
  }
  let result = @src.render_template_bundle_json_checked(
    bundle, context_json, options,
  )
  bundle_response_json(result)
}

///|
test "starter bridge renders five checked artifacts" {
  let response = generate_starter_bridge(
    "{\"package\":\"example/starter\",\"display_name\":\"Starter\",\"description\":\"Generated project.\"}",
    true,
  )
  inspect(response.contains("\"path\":\"moon.mod\""), content="true")
  inspect(response.contains("\"path\":\"README.md\""), content="true")
  inspect(response.contains("\"path\":\"src/main.mbt\""), content="true")
  inspect(
    response.contains("\"path\":\".github/workflows/ci.yml\""),
    content="true",
  )
  inspect(response.contains("\"errors\":[]"), content="true")
}
