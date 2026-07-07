///|
fn make_object(entries : Array[(String, Value)]) -> Value {
  let map : Map[String, Value] = {}
  for entry in entries {
    map[entry.0] = entry.1
  }
  Value::object(map)
}

///|
fn run_spec_case(
  template : String,
  data_json : String,
  expected : String,
  partials_json? : String = "{}",
) -> Unit raise InspectError {
  let result = render_json_bundle_checked(template, data_json, partials_json)
  inspect(result.output, content=expected)
  inspect(result.errors.length(), content="0")
}

///|
test "escape_html handles reserved characters" {
  let actual = escape_html("<tag>&\"'")
  inspect(actual, content="&lt;tag&gt;&amp;&quot;&#39;")
}

///|
test "render_string keeps plain text" {
  let actual = render("hello", Value::empty_object())
  inspect(actual, content="hello")
}

///|
test "render_string renders escaped variables" {
  let context = make_object([("name", Value::string("<MoonBit>"))])
  let actual = render("hello {{name}}", context)
  inspect(actual, content="hello &lt;MoonBit&gt;")
}

///|
test "render_string renders triple mustache without escaping" {
  let context = make_object([("name", Value::string("<MoonBit>"))])
  let actual = render("hello {{{name}}}", context)
  inspect(actual, content="hello <MoonBit>")
}

///|
test "render_string renders ampersand variables without escaping" {
  let context = make_object([("name", Value::string("<MoonBit>"))])
  let actual = render("hello {{& name}}", context)
  inspect(actual, content="hello <MoonBit>")
}

///|
test "render_string supports dotted lookup" {
  let user = make_object([("name", Value::string("Moon"))])
  let context = make_object([("user", user)])
  let actual = render("hello {{user.name}}", context)
  inspect(actual, content="hello Moon")
}

///|
test "render_string ignores comments" {
  let actual = render("A{{! hidden }}B", Value::empty_object())
  inspect(actual, content="AB")
}

///|
test "truthy section renders children once" {
  let profile = make_object([("name", Value::string("MoonBit"))])
  let context = make_object([("profile", profile)])
  let actual = render("{{#profile}}Hi {{name}}!{{/profile}}", context)
  inspect(actual, content="Hi MoonBit!")
}

///|
test "inverted section renders when value is false" {
  let context = make_object([("enabled", Value::bool(false))])
  let actual = render("{{^enabled}}disabled{{/enabled}}", context)
  inspect(actual, content="disabled")
}

///|
test "array section iterates items and supports current context" {
  let items = Value::array([
    Value::string("a"),
    Value::string("b"),
    Value::string("c"),
  ])
  let context = make_object([("items", items)])
  let actual = render("{{#items}}[{{.}}]{{/items}}", context)
  inspect(actual, content="[a][b][c]")
}

///|
test "array section can still read parent scope values" {
  let context = make_object([
    ("category", Value::string("core")),
    (
      "items",
      Value::array([
        make_object([("name", Value::string("scanner"))]),
        make_object([("name", Value::string("renderer"))]),
      ]),
    ),
  ])
  let actual = render("{{#items}}{{category}}/{{name}};{{/items}}", context)
  inspect(actual, content="core/scanner;core/renderer;")
}

///|
test "scanner supports delimiter changes" {
  let context = make_object([("name", Value::string("MoonBit"))])
  let actual = render("{{=<% %>=}}Hello, <%name%>!", context)
  inspect(actual, content="Hello, MoonBit!")
}

///|
test "render_string renders partials with current context" {
  let context = make_object([
    ("name", Value::string("MoonBit")),
    ("role", Value::string("template engine")),
  ])
  let partials : Map[String, String] = { "card": "{{name}} builds a {{role}}." }
  let actual = render_with_partials("Project: {{> card}}", context, partials)
  inspect(actual, content="Project: MoonBit builds a template engine.")
}

///|
test "render_string renders partials inside sections" {
  let context = make_object([
    (
      "items",
      Value::array([
        make_object([("name", Value::string("scanner"))]),
        make_object([("name", Value::string("renderer"))]),
      ]),
    ),
  ])
  let partials : Map[String, String] = { "item": "- {{name}}\n" }
  let actual = render_with_partials(
    "{{#items}}{{> item}}{{/items}}", context, partials,
  )
  inspect(actual, content="- scanner\n- renderer\n")
}

///|
test "render_string skips missing partials" {
  let actual = render_with_partials("A{{> missing}}B", Value::empty_object(), {})
  inspect(actual, content="AB")
}

///|
test "render_checked reports missing partials" {
  let result = render_with_partials_checked(
    "A{{> missing}}B",
    Value::empty_object(),
    {},
  )
  inspect(result.output, content="AB")
  inspect(result.errors.length(), content="1")
  inspect(result.errors[0], content="missing partial: missing")
}

///|
test "render_checked reports parse errors" {
  let result = render_checked("{{#user}}Hello", Value::empty_object())
  inspect(result.errors.length(), content="1")
  inspect(result.errors[0], content="unterminated section: user")
}

///|
test "render_checked reports malformed partial templates" {
  let partials : Map[String, String] = { "broken": "{{#user}}Hello" }
  let result = render_with_partials_checked(
    "A{{> broken}}B",
    Value::empty_object(),
    partials,
  )
  inspect(result.output, content="AB")
  inspect(result.errors.length(), content="1")
  inspect(
    result.errors[0],
    content="partial broken: unterminated section: user",
  )
}

///|
test "parse_json_context supports nested objects and arrays" {
  let context = parse_json_context(
    "{\"user\":{\"name\":\"MoonBit\"},\"items\":[\"scanner\",\"renderer\"]}",
  ) catch {
    _ => panic()
  }
  let actual = render("{{user.name}}:{{#items}} {{.}}{{/items}}", context)
  inspect(actual, content="MoonBit: scanner renderer")
}

///|
test "parse_json_context supports booleans and inverted sections" {
  let context = parse_json_context("{\"enabled\":false}") catch { _ => panic() }
  let actual = render("{{^enabled}}disabled{{/enabled}}", context)
  inspect(actual, content="disabled")
}

///|
test "parse_json_partials_checked parses partial maps" {
  let parsed = parse_json_partials_checked(
    "{\"card\":\"{{name}} builds tooling.\"}",
  )
  match parsed {
    Ok(partials) => {
      inspect(partials.length(), content="1")
      inspect(partials.get("card").unwrap(), content="{{name}} builds tooling.")
    }
    Err(_) => panic()
  }
}

///|
test "render_json_bundle_checked renders template with partial JSON" {
  let result = render_json_bundle_checked(
    "Project: {{> card}}", "{\"name\":\"MoonBit\"}", "{\"card\":\"{{name}} builds tooling.\"}",
  )
  inspect(result.output, content="Project: MoonBit builds tooling.")
  inspect(result.errors.length(), content="0")
}

///|
test "object_from_string_entries supports dotted names and typed values" {
  let (context, errors) = object_from_string_entries([
    ("user.name", "Alice"),
    ("enabled", "true"),
    ("count", "3"),
  ])
  inspect(errors.length(), content="0")
  let actual = render("{{user.name}}/{{enabled}}/{{count}}", context)
  inspect(actual, content="Alice/true/3")
}

///|
test "merge_values merges nested objects" {
  let base = make_object([
    (
      "project",
      make_object([
        ("name", Value::string("moon-mustache")),
        ("owner", Value::string("community")),
      ]),
    ),
  ])
  let incoming = make_object([
    ("project", make_object([("owner", Value::string("Alice"))])),
  ])
  let merged = merge_values(base, incoming)
  let actual = render("{{project.name}}/{{project.owner}}", merged)
  inspect(actual, content="moon-mustache/Alice")
}

///|
test "render_checked_with_options reports missing variables" {
  let result = render_checked_with_options(
    "Hello {{name}} from {{project}}",
    Value::empty_object(),
    RenderOptions::strict(),
  )
  inspect(result.output, content="Hello  from ")
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="2")
  inspect(result.missing_variables[0], content="name")
  inspect(result.missing_variables[1], content="project")
}

///|
test "render_json_checked_with_options preserves parse diagnostics" {
  let result = render_json_checked_with_options(
    "{{name}}",
    "{broken}",
    {},
    RenderOptions::strict(),
  )
  inspect(result.output, content="")
  inspect(result.errors.length(), content="1")
  inspect(result.missing_variables.length(), content="0")
}

///|
test "render_template_bundle_checked renders multiple files" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("README.md", "# {{name}}"),
      TemplateFile::new(".env", "APP_NAME={{name}}"),
    ],
    {},
  )
  let context = make_object([("name", Value::string("moon-mustache"))])
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  inspect(result.files.length(), content="2")
  inspect(result.errors.length(), content="0")
  inspect(result.files[0].output, content="# moon-mustache")
  inspect(result.files[1].output, content="APP_NAME=moon-mustache")
}

///|
test "render_template_bundle_checked aggregates missing variables" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("README.md", "# {{name}}"),
      TemplateFile::new(".env", "APP_NAME={{name}}\nOWNER={{owner}}"),
    ],
    {},
  )
  let result = render_template_bundle_checked(
    bundle,
    Value::empty_object(),
    RenderOptions::strict(),
  )
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="2")
  inspect(result.missing_variables[0], content="name")
  inspect(result.missing_variables[1], content="owner")
}

///|
test "parse_bundle_manifest_json parses file list and partials" {
  let manifest_json =
    #|{
    #|  "name": "demo",
    #|  "context": { "project": { "network": "demo-net" } },
    #|  "partials": { "footer": "bye" },
    #|  "profiles": {
    #|    "dev": {
    #|      "context": { "project": { "port": 3000 } }
    #|    }
    #|  },
    #|  "files": [
    #|    { "path": "README.md", "template": "# {{name}}" },
    #|    { "path": ".env", "template": "APP={{name}}" }
    #|  ]
    #|}
  let parsed = parse_bundle_manifest_json(manifest_json)
  match parsed {
    Ok(manifest) => {
      inspect(manifest.name, content="demo")
      inspect(manifest.bundle.files.length(), content="2")
      inspect(manifest.bundle.partials.get("footer").unwrap(), content="bye")
      inspect(manifest.profiles.length(), content="1")
    }
    Err(_) => panic()
  }
}

///|
test "render_bundle_manifest_json_checked renders manifest bundle" {
  let manifest = sample_bundle_manifest_json()
  let context_json = "{\"project\":{\"name\":\"moon-mustache\",\"port\":8080},\"features\":[\"cli\",\"spec report\"]}"
  let result = render_bundle_manifest_json_checked(
    manifest,
    context_json,
    RenderOptions::strict(),
  )
  match result {
    Ok(bundle_result) => {
      inspect(bundle_result.files.length(), content="2")
      inspect(bundle_result.errors.length(), content="0")
      inspect(bundle_result.files[0].path, content=".env")
    }
    Err(_) => panic()
  }
}

///|
test "resolve_bundle_manifest_profile merges base and profile context" {
  let manifest = parse_bundle_manifest_json(sample_bundle_manifest_json()).unwrap()
  let runtime_context = make_object([
    ("project", make_object([("name", Value::string("moon-mustache"))])),
    ("features", Value::array([Value::string("cli")])),
  ])
  let resolved = resolve_bundle_manifest_profile(
    manifest,
    runtime_context,
    profile_name="dev",
  ).unwrap()
  let result = render_template_bundle_checked(
    resolved.bundle,
    resolved.context,
    RenderOptions::default(),
  )
  inspect(result.files.length(), content="2")
  inspect(result.files[0].output.contains("APP_PORT=3000"), content="true")
  inspect(result.files[0].output.contains("NETWORK=sample-net"), content="true")
}

///|
test "render_bundle_manifest_json_with_profile_checked applies profile partials" {
  let context_json = "{\"project\":{\"name\":\"moon-mustache\"},\"features\":[\"bundle\"]}"
  let result = render_bundle_manifest_json_with_profile_checked(
    sample_bundle_manifest_json(),
    context_json,
    RenderOptions::default(),
    profile_name="prod",
  )
  match result {
    Ok(bundle_result) => {
      inspect(bundle_result.files.length(), content="2")
      inspect(
        bundle_result.files[0].output.contains("APP_PORT=8080"),
        content="true",
      )
      inspect(
        bundle_result.files[1].output.contains("# Generated for production"),
        content="true",
      )
    }
    Err(_) => panic()
  }
}

///|
test "format_bundle_result_markdown includes file sections" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("README.md", "# {{name}}")],
    {},
  )
  let context = make_object([("name", Value::string("moon-mustache"))])
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  let markdown = format_bundle_result_markdown("demo", result)
  inspect(markdown.contains("# Bundle Render Report"), content="true")
  inspect(markdown.contains("## README.md"), content="true")
}

///|
test "format_bundle_result_json includes bundle name" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("README.md", "# {{name}}")],
    {},
  )
  let context = make_object([("name", Value::string("moon-mustache"))])
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  let json = format_bundle_result_json("demo", result)
  inspect(json.contains("\"bundle\":\"demo\""), content="true")
  inspect(json.contains("\"path\":\"README.md\""), content="true")
}

///|
test "normalize_bundle_path rewrites separators and rejects traversal" {
  let normalized = normalize_bundle_path("deploy\\config/./app.toml").unwrap()
  inspect(normalized, content="deploy/config/app.toml")
  let invalid = normalize_bundle_path("../secret.txt")
  match invalid {
    Ok(_) => panic()
    Err(message) =>
      inspect(message.contains("parent traversal"), content="true")
  }
}

///|
test "validate_template_bundle detects duplicate normalized paths" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("a/../bad.txt", "x"),
      TemplateFile::new("deploy\\config.toml", "x"),
      TemplateFile::new("deploy/config.toml", "y"),
    ],
    {},
  )
  let result = validate_template_bundle(bundle)
  inspect(validation_error_count(result), content="2")
  inspect(result.issues.length() >= 2, content="true")
}

///|
test "validate_bundle_manifest reports empty profile partials as warnings" {
  let manifest_json =
    #|{
    #|  "name": "demo",
    #|  "profiles": {
    #|    "prod": {
    #|      "partials": {
    #|        "banner": ""
    #|      }
    #|    }
    #|  },
    #|  "files": [
    #|    { "path": "README.md", "template": "# hi" }
    #|  ]
    #|}
  let manifest = parse_bundle_manifest_json(manifest_json).unwrap()
  let result = validate_bundle_manifest(manifest)
  inspect(validation_warning_count(result), content="1")
}

///|
test "build_bundle_plan includes normalized paths and counts" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("deploy\\config.toml", "service={{name}}\n")],
    {},
  )
  let context = make_object([("name", Value::string("moon-mustache"))])
  let render_result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  let validation_result = validate_template_bundle(bundle)
  let plan = build_bundle_plan("demo", render_result, validation_result)
  inspect(plan.files.length(), content="1")
  inspect(plan.files[0].normalized_path, content="deploy/config.toml")
  inspect(plan.files[0].output_lines.to_string(), content="2")
}

///|
test "format_validation_report_markdown includes table rows" {
  let bundle = TemplateBundle::new([TemplateFile::new("", "")], {})
  let result = validate_template_bundle(bundle)
  let report = format_validation_report_markdown("demo", result)
  inspect(report.contains("# Bundle Validation Report"), content="true")
  inspect(report.contains("| error | invalid-output-path |"), content="true")
}

///|
test "format_bundle_plan_markdown includes normalized path column" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("README.md", "# {{name}}")],
    {},
  )
  let context = make_object([("name", Value::string("moon-mustache"))])
  let render_result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  let validation_result = validate_template_bundle(bundle)
  let plan = build_bundle_plan("demo", render_result, validation_result)
  let report = format_bundle_plan_markdown(plan)
  inspect(report.contains("# Bundle Generation Plan"), content="true")
  inspect(report.contains("Normalized path"), content="true")
}

///|
test "spec style: sections standalone lines trim surrounding whitespace" {
  run_spec_case(
    "| This Is\n{{#boolean}}\n|\n{{/boolean}}\n| A Line\n", "{\"boolean\":true}",
    "| This Is\n|\n| A Line\n",
  )
}

///|
test "spec style: inverted sections standalone lines trim surrounding whitespace" {
  run_spec_case(
    "| This Is\n{{^boolean}}\n|\n{{/boolean}}\n| A Line\n", "{\"boolean\":false}",
    "| This Is\n|\n| A Line\n",
  )
}

///|
test "spec style: comments standalone lines are removed cleanly" {
  run_spec_case("Begin.\n{{! Comment Block! }}\nEnd.\n", "{}", "Begin.\nEnd.\n")
}

///|
test "spec style: partial recursion renders nested expansion" {
  run_spec_case(
    "{{> node}}",
    "{\"content\":\"X\",\"nodes\":[{\"content\":\"Y\",\"nodes\":[]}]}",
    "X<Y<>>",
    partials_json="{\"node\":\"{{content}}<{{#nodes}}{{> node}}{{/nodes}}>\"}",
  )
}

///|
test "parse_template builds section tree without errors" {
  let parsed = parse("{{#user}}Hi {{name}}{{/user}}")
  inspect(parsed.errors.length(), content="0")
  inspect(parsed.nodes.length(), content="1")
}

///|
test "parse_template reports unterminated sections" {
  let parsed = parse("{{#user}}Hi")
  inspect(parsed.errors.length(), content="1")
}

///|
test "value_to_string handles string values" {
  let actual = value_to_string(Value::string("moonbit"))
  inspect(actual, content="moonbit")
}
