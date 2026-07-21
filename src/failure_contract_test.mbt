///|
fn expect_manifest_error(
  input : String,
  expected : String,
) -> Unit raise InspectError {
  match parse_bundle_manifest_json(input) {
    Ok(_) => panic()
    Err(message) => inspect(message.contains(expected), content="true")
  }
}

///|
test "partials JSON rejects syntax and non-string values" {
  match parse_json_partials_checked("{") {
    Ok(_) => panic()
    Err(message) =>
      inspect(message.contains("invalid partials JSON"), content="true")
  }
  match parse_json_partials_checked("{\"card\":42}") {
    Ok(_) => panic()
    Err(message) =>
      inspect(message.contains("invalid partials JSON"), content="true")
  }
}

///|
test "checked JSON wrappers return diagnostics instead of raising" {
  let direct = render_json_checked("Hello {{name}}", "{", {})
  inspect(direct.output, content="")
  inspect(direct.errors.length(), content="1")
  inspect(direct.errors[0].contains("invalid JSON context"), content="true")

  let prepared = prepare("Hello {{name}}", {})
  let prepared_result = render_prepared_json_checked(prepared, "{")
  inspect(prepared_result.output, content="")
  inspect(prepared_result.errors.length(), content="1")

  let bundle_result = render_json_bundle_checked("{{> card}}", "{}", "{")
  inspect(bundle_result.output, content="")
  inspect(bundle_result.errors.length(), content="1")
  inspect(
    bundle_result.errors[0].contains("invalid partials JSON"),
    content="true",
  )
}

///|
test "bundle JSON wrappers preserve invalid-context failures" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("README.md", "# {{name}}")],
    {},
  )
  let direct = render_template_bundle_json_checked(
    bundle,
    "{",
    RenderOptions::default(),
  )
  inspect(direct.files.length(), content="0")
  inspect(direct.errors.length(), content="1")
  inspect(direct.errors[0].contains("invalid JSON context"), content="true")

  let prepared = prepare_template_bundle(bundle)
  let prepared_result = render_prepared_template_bundle_json_checked(
    prepared,
    "{",
    RenderOptions::default(),
  )
  inspect(prepared_result.files.length(), content="0")
  inspect(prepared_result.errors.length(), content="1")
}

///|
test "bundle rendering reports path errors and deduplicates missing names" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("{{{path}}}", "{{missing}}/{{missing}}"),
      TemplateFile::new("{{#broken}}", "ok"),
    ],
    {},
  )
  let context = make_object([("path", Value::string("../secret.txt"))])
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::strict(),
  )
  inspect(result.files.length(), content="2")
  inspect(result.errors.length() > 0, content="true")
  let mut found_parent_traversal = false
  for error in result.errors {
    if error.contains("parent traversal") {
      found_parent_traversal = true
    }
  }
  inspect(found_parent_traversal, content="true")
  inspect(result.missing_variables.length(), content="1")
  inspect(result.missing_variables[0], content="missing")
  inspect(bundle_has_issues(result), content="true")
}

///|
test "empty rendered bundle path falls back to its path template" {
  let file = TemplateFile::new("{{missing}}", "ok")
  let rendered = render_template_file_checked(
    file,
    Value::empty_object(),
    {},
    RenderOptions::strict(),
  )
  inspect(rendered.path, content="{{missing}}")
  inspect(rendered.missing_variables.length(), content="1")
}

///|
test "bundle_has_issues distinguishes clean output" {
  let clean = render_template_bundle_checked(
    TemplateBundle::new([], {}),
    Value::empty_object(),
    RenderOptions::default(),
  )
  let missing = render_template_bundle_checked(
    TemplateBundle::new([TemplateFile::new("output.txt", "{{name}}")], {}),
    Value::empty_object(),
    RenderOptions::strict(),
  )
  inspect(bundle_has_issues(clean), content="false")
  inspect(bundle_has_issues(missing), content="true")
}

///|
test "bundle reports include failures and emit valid escaped JSON" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("../{{first}}.md", "line 1\nline 2 {{second}}"),
      TemplateFile::new("two\".md", "tab\tbackslash\\return\r"),
    ],
    {},
  )
  let result = render_template_bundle_checked(
    bundle,
    Value::empty_object(),
    RenderOptions::strict(),
  )
  let markdown = format_bundle_result_markdown("failure-demo", result)
  inspect(markdown.contains("## Errors"), content="true")
  inspect(markdown.contains("## Missing Variables"), content="true")
  inspect(markdown.contains("- second"), content="true")

  let json = format_bundle_result_json("failure\"demo", result)
  let parsed = @json.parse(json) catch { _ => panic() }
  match parsed {
    Object(_) => ()
    _ => panic()
  }
  inspect(json.contains("failure\\\"demo"), content="true")
  inspect(json.contains("line 1\\nline 2"), content="true")
  inspect(json.contains("tab\\tbackslash\\\\return\\r"), content="true")
}

///|
test "manifest parser explains malformed shapes" {
  expect_manifest_error("{", "invalid bundle manifest JSON")
  expect_manifest_error("[]", "must be a JSON object")
  expect_manifest_error("{}", "missing array field `files`")
  expect_manifest_error(
    "{\"name\":1,\"files\":[]}", "field `name` must be a string",
  )
  expect_manifest_error("{\"files\":{}}", "field `files` must be an array")
  expect_manifest_error("{\"files\":[1]}", "file entry must be an object")
  expect_manifest_error(
    "{\"files\":[{\"template\":\"x\"}]}", "missing string field `path`",
  )
  expect_manifest_error(
    "{\"files\":[{\"path\":1,\"template\":\"x\"}]}", "field `path` must be a string",
  )
  expect_manifest_error(
    "{\"files\":[{\"path\":\"x\"}]}", "missing string field `template`",
  )
  expect_manifest_error(
    "{\"files\":[{\"path\":\"x\",\"template\":1}]}", "field `template` must be a string",
  )
  expect_manifest_error(
    "{\"files\":[],\"partials\":{\"card\":1}}", "invalid manifest partials",
  )
  expect_manifest_error(
    "{\"files\":[],\"profiles\":[]}", "field `profiles` must be an object",
  )
  expect_manifest_error(
    "{\"files\":[],\"profiles\":{\"dev\":1}}", "bundle profile entry must be an object",
  )
  expect_manifest_error(
    "{\"files\":[],\"profiles\":{\"dev\":{\"partials\":{\"x\":1}}}}", "invalid profile partials",
  )
}

///|
test "manifest JSON helpers report unknown profiles and invalid context" {
  let manifest = sample_bundle_manifest_json()
  match
    render_bundle_manifest_json_with_profile_checked(
      manifest,
      "{}",
      RenderOptions::default(),
      profile_name="missing",
    ) {
    Ok(_) => panic()
    Err(message) => inspect(message, content="unknown bundle profile: missing")
  }
  match
    prepare_bundle_manifest_json_profile(manifest, "{", profile_name="dev") {
    Ok(_) => panic()
    Err(message) =>
      inspect(message.contains("invalid JSON context"), content="true")
  }
}
