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
  let actual = escape_html("<tag>&\"'/`=<tag>&")
  inspect(
    actual,
    content="&lt;tag&gt;&amp;&quot;&#39;&#x2F;&#x60;&#x3D;&lt;tag&gt;&amp;",
  )
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
test "true boolean section renders children" {
  let context = make_object([("enabled", Value::bool(true))])
  let actual = render("{{#enabled}}enabled{{/enabled}}", context)
  inspect(actual, content="enabled")
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
test "scan_template_variables collects data lookups in traversal order" {
  let names = scan_template_variables(
    "{{#user}}{{name}}{{/user}}{{^enabled}}{{message}}{{/enabled}}{{#items}}{{.}}{{/items}}",
  )
  inspect(names.length(), content="5")
  inspect(names[0], content="user")
  inspect(names[1], content="name")
  inspect(names[2], content="enabled")
  inspect(names[3], content="message")
  inspect(names[4], content="items")
}

///|
test "scan_template_references reports partials delimiters and dotted names" {
  let result = scan_template_references(
    "{{=<% %>=}}<%#items%><%user.name%><%/items%><%> card%>",
  )
  inspect(result.data_names.length(), content="2")
  inspect(result.data_names[0], content="items")
  inspect(result.data_names[1], content="user.name")
  inspect(result.partial_names.length(), content="1")
  inspect(result.partial_names[0], content="card")
  inspect(result.references.length(), content="3")
  inspect(result.uses_dotted_names, content="true")
  inspect(result.uses_current_context, content="false")
  inspect(result.delimiter_change_count.to_string(), content="1")
  inspect(result.parse_errors.length(), content="0")
}

///|
test "scan_template_references preserves parse diagnostics" {
  let result = scan_template_references("{{#user}}{{name}}")
  inspect(result.data_names.length(), content="2")
  inspect(result.parse_errors.length(), content="1")
  inspect(result.parse_errors[0], content="unterminated section: user")
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
test "prepare compiles template for repeated render paths" {
  let prepared = prepare("{{#users}}{{> user}}{{/users}}", {
    "user": "[{{name}}:{{role}}]",
  })
  let context = make_object([
    (
      "users",
      Value::array([
        make_object([
          ("name", Value::string("Alice")),
          ("role", Value::string("admin")),
        ]),
        make_object([
          ("name", Value::string("Bob")),
          ("role", Value::string("developer")),
        ]),
      ]),
    ),
  ])
  let result = render_prepared_checked(prepared, context)
  inspect(result.output, content="[Alice:admin][Bob:developer]")
  inspect(result.errors.length(), content="0")
}

///|
test "render_prepared_json_checked preserves strict missing variable diagnostics" {
  let prepared = prepare("{{name}}/{{owner}}", {})
  let result = render_prepared_json_checked_with_options(
    prepared,
    "{\"name\":\"moon-mustache\"}",
    RenderOptions::strict(),
  )
  inspect(result.output, content="moon-mustache/")
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="1")
  inspect(result.missing_variables[0], content="owner")
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
test "render_checked_with_options deduplicates repeated missing variables" {
  let result = render_checked_with_options(
    "{{name}}/{{name}}/{{owner}}/{{name}}",
    Value::empty_object(),
    RenderOptions::strict(),
  )
  inspect(result.output, content="///")
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="2")
  inspect(result.missing_variables[0], content="name")
  inspect(result.missing_variables[1], content="owner")
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
test "render_template_bundle_checked renders output paths from template context" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("deploy/{{service}}/config.toml", "service={{service}}")],
    {},
  )
  let context = make_object([("service", Value::string("moon-mustache"))])
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  inspect(result.files.length(), content="1")
  inspect(result.errors.length(), content="0")
  inspect(result.files[0].path, content="deploy/moon-mustache/config.toml")
}

///|
test "render_template_bundle_checked reports invalid rendered output paths" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("../{{service}}/config.toml", "service={{service}}")],
    {},
  )
  let context = make_object([("service", Value::string("moon-mustache"))])
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::default(),
  )
  inspect(result.files.length(), content="1")
  inspect(result.errors.length(), content="1")
  inspect(
    result.errors[0].contains("rendered output path: parent traversal"),
    content="true",
  )
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
test "render_template_bundle_checked deduplicates path and body misses" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("deploy/{{name}}/README.md", "{{name}}\n{{name}}\n")],
    {},
  )
  let result = render_template_bundle_checked(
    bundle,
    Value::empty_object(),
    RenderOptions::strict(),
  )
  inspect(result.errors.length(), content="0")
  inspect(result.files.length(), content="1")
  inspect(result.files[0].missing_variables.length(), content="1")
  inspect(result.files[0].missing_variables[0], content="name")
  inspect(result.missing_variables.length(), content="1")
  inspect(result.missing_variables[0], content="name")
}

///|
test "prepare_template_bundle reuses compiled templates across files" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("README.md", "# {{name}}\n{{> footer}}"),
      TemplateFile::new("docs/guide.md", "Guide for {{name}}\n{{> footer}}"),
    ],
    { "footer": "Generated by {{owner}}" },
  )
  let prepared = prepare_template_bundle(bundle)
  let context = make_object([
    ("name", Value::string("moon-mustache")),
    ("owner", Value::string("MoonBit Community")),
  ])
  let result = render_prepared_template_bundle_checked(
    prepared,
    context,
    RenderOptions::default(),
  )
  inspect(result.files.length(), content="2")
  inspect(result.errors.length(), content="0")
  inspect(
    result.files[0].output.contains("Generated by MoonBit Community"),
    content="true",
  )
  inspect(
    result.files[1].output.contains("Guide for moon-mustache"),
    content="true",
  )
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
test "prepare_bundle_manifest_profile compiles resolved profile bundle" {
  let manifest = parse_bundle_manifest_json(sample_bundle_manifest_json()).unwrap()
  let runtime_context = make_object([
    ("project", make_object([("name", Value::string("moon-mustache"))])),
    ("features", Value::array([Value::string("bundle")])),
  ])
  let prepared = prepare_bundle_manifest_profile(
    manifest,
    runtime_context,
    profile_name="prod",
  ).unwrap()
  let result = render_prepared_bundle_manifest_checked(
    prepared,
    RenderOptions::default(),
  )
  inspect(result.files.length(), content="2")
  inspect(result.files[0].output.contains("APP_PORT=8080"), content="true")
  inspect(
    result.files[1].output.contains("# Generated for production"),
    content="true",
  )
}

///|
test "prepare_bundle_manifest_json_profile validates json context once" {
  let prepared = prepare_bundle_manifest_json_profile(
    sample_bundle_manifest_json(),
    "{\"project\":{\"name\":\"moon-mustache\"},\"features\":[\"bundle\"]}",
    profile_name="dev",
  ).unwrap()
  let result = render_prepared_bundle_manifest_checked(
    prepared,
    RenderOptions::strict(),
  )
  inspect(result.errors.length(), content="0")
  inspect(result.files.length(), content="2")
  inspect(result.files[0].output.contains("APP_PORT=3000"), content="true")
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
test "normalize_bundle_path rejects absolute and drive-qualified paths" {
  match normalize_bundle_path("") {
    Ok(_) => panic()
    Err(message) => inspect(message, content="path must not be empty")
  }
  match normalize_bundle_path("/etc/passwd") {
    Ok(_) => panic()
    Err(message) =>
      inspect(
        message.contains("absolute paths are not allowed"),
        content="true",
      )
  }
  match normalize_bundle_path("\\windows\\system32") {
    Ok(_) => panic()
    Err(message) =>
      inspect(
        message.contains("absolute paths are not allowed"),
        content="true",
      )
  }
  match normalize_bundle_path("C:\\temp\\output.txt") {
    Ok(_) => panic()
    Err(message) =>
      inspect(
        message.contains("drive-qualified paths are not allowed"),
        content="true",
      )
  }
  match normalize_bundle_path("././") {
    Ok(_) => panic()
    Err(message) => inspect(message.contains("empty location"), content="true")
  }
}

///|
test "dynamic partial selects a partial from the current context" {
  let context = make_object([
    ("which", Value::string("card")),
    ("name", Value::string("MoonBit")),
  ])
  let result = render_with_partials_checked("{{>*which}}", context, {
    "card": "Hello {{name}}",
  })
  inspect(result.output, content="Hello MoonBit")
  inspect(result.errors.length(), content="0")
}

///|
test "parent templates apply block overrides and preserve indentation" {
  let context = make_object([("name", Value::string("MoonBit"))])
  let result = render_with_partials_checked(
    "{{<layout}}{{$body}}\n    Project: {{name}}\n    Ready\n{{/body}}{{/layout}}\n",
    context,
    { "layout": "Layout:\n  {{$body}}\n  Default\n  {{/body}}\n" },
  )
  inspect(result.errors.length(), content="0")
  inspect(result.output, content="Layout:\n  Project: MoonBit\n  Ready\n")
}

///|
test "parent block overrides preserve raw variables and inverted sections" {
  let context = make_object([("html", Value::string("<b>MoonBit</b>"))])
  let result = render_with_partials_checked(
    "{{<layout}}{{$body}}\n    {{{html}}}\n{{^missing}}    fallback{{/missing}}\n{{/body}}{{/layout}}",
    context,
    { "layout": "Layout:\n  {{$body}}\n  {{/body}}\n" },
  )
  inspect(result.errors.length(), content="0")
  inspect(result.output, content="Layout:\n  <b>MoonBit</b>\n  fallback\n")
}

///|
test "value_to_string preserves checked scalar and container semantics" {
  inspect(value_to_string(Value::null()), content="")
  inspect(value_to_string(Value::bool(true)), content="true")
  inspect(value_to_string(Value::bool(false)), content="false")
  inspect(value_to_string(Value::number(3.5)), content="3.5")
  inspect(value_to_string(Value::object({})), content="[object]")
  inspect(value_to_string(Value::array([])), content="[array]")
  inspect(
    value_to_string(Value::interpolation_lambda(fn() { "ignored" })),
    content="",
  )
}

///|
test "diagnostic helpers clamp spans and format severity labels" {
  let warning = make_warning_diagnostic(
    "first\nsecond",
    "MST-WARN",
    "check this",
    -4,
    99,
    source_name="demo.mustache",
  )
  inspect(warning.severity.label(), content="warning")
  inspect(warning.span.line, content="1")
  inspect(warning.span.column, content="1")
  inspect(
    format_diagnostic(warning).contains("demo.mustache:1:1: warning"),
    content="true",
  )

  let info = make_info_diagnostic("", "MST-INFO", "done", 10, 2)
  inspect(info.severity.label(), content="info")
  inspect(
    format_diagnostic(info),
    content="<template>:1:1: info [MST-INFO] done",
  )
}

///|
test "context lookup handles current values and empty stacks" {
  inspect(lookup_name([], "missing") is None, content="true")
  let value = Value::object({ "name": Value::string("MoonBit") })
  inspect(lookup_name([value], ".") is Some(_), content="true")
  inspect(
    lookup_name([Value::object({ "name": Value::string("MoonBit") })], "name..")
    is Some(_),
    content="true",
  )
}

///|
test "path_line_count treats empty and newline-terminated content consistently" {
  inspect(path_line_count(""), content="0")
  inspect(path_line_count("one\n"), content="2")
  inspect(path_line_count("one\ntwo"), content="2")
}

///|
test "strict dynamic partial reports an unresolved selector" {
  let result = render_with_partials_checked_with_options(
    "{{>*missing_partial}}",
    Value::empty_object(),
    { "card": "unused" },
    RenderOptions::strict(),
  )
  inspect(result.output, content="")
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="1")
  inspect(result.missing_variables[0], content="missing_partial")
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
test "parse_template reports structured source diagnostics" {
  let parsed = parse("Hello\n{{/user}}")
  inspect(parsed.diagnostics.length(), content="1")
  inspect(parsed.diagnostics[0].code, content="MST-PARSE-001")
  inspect(parsed.diagnostics[0].span.line, content="2")
  inspect(parsed.diagnostics[0].span.column, content="1")
}

///|
test "lint reports missing variables with source positions" {
  let report = lint_template("Hello {{user.name}}", Value::empty_object(), {})
  inspect(lint_error_count(report), content="1")
  inspect(report.diagnostics[0].code, content="MST-LINT-001")
  inspect(report.diagnostics[0].span.column, content="7")
}

///|
test "lint reports missing partials and partial cycles" {
  let missing = lint_template("{{> card}}", Value::empty_object(), {})
  inspect(lint_error_count(missing), content="1")
  inspect(missing.diagnostics[0].code, content="MST-LINT-002")
  let cyclic = lint_template("{{> first}}", Value::empty_object(), {
    "first": "{{> second}}",
    "second": "{{> first}}",
  })
  inspect(lint_has_errors(cyclic), content="true")
  inspect(format_lint_report(cyclic).contains("MST-LINT-003"), content="true")
}

///|
test "lint bundle includes unsafe output path diagnostics" {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("../secret.txt", "safe")],
    {},
  )
  let report = lint_template_bundle(bundle, Value::empty_object())
  inspect(lint_has_errors(report), content="true")
  inspect(
    format_lint_report(report).contains("MST-BUNDLE-invalid-output-path"),
    content="true",
  )
}

///|
test "lint json reports malformed context" {
  let report = lint_template_json("Hello {{name}}", "{", {})
  inspect(lint_error_count(report), content="1")
  inspect(report.diagnostics[0].code, content="MST-LINT-004")
}

///|
test "render resource budget limits output length" {
  let options = RenderOptions::default().with_resource_limits(5, 100, 100)
  let result = render_checked_with_options(
    "abcdefghij",
    Value::empty_object(),
    options,
  )
  inspect(result.output, content="abcde")
  inspect(result.errors[0].contains("MST-LIMIT-001"), content="true")
}

///|
test "render resource budget limits section iterations" {
  let context = make_object([
    (
      "items",
      Value::array([Value::string("1"), Value::string("2"), Value::string("3")]),
    ),
  ])
  let options = RenderOptions::default().with_resource_limits(100, 2, 100)
  let result = render_checked_with_options(
    "{{#items}}{{.}}{{/items}}", context, options,
  )
  inspect(result.output, content="12")
  inspect(result.errors[0].contains("MST-LIMIT-002"), content="true")
}

///|
test "render resource budget limits total render steps" {
  let context = make_object([("name", Value::string("MoonBit"))])
  let options = RenderOptions::default().with_resource_limits(100, 100, 2)
  let result = render_checked_with_options("A{{name}}B", context, options)
  inspect(result.output, content="AMoonBit")
  inspect(result.errors[0].contains("MST-LIMIT-003"), content="true")
}

///|
test "render resource budget limits partial depth" {
  let options = RenderOptions::default().with_partial_depth_limit(1)
  let result = render_with_partials_checked_with_options(
    "{{> first}}",
    Value::empty_object(),
    { "first": "{{> second}}", "second": "should-not-render" },
    options,
  )
  inspect(result.output, content="")
  inspect(result.errors.length(), content="1")
  inspect(
    result.errors[0].contains("partial depth limit exceeded"),
    content="true",
  )
}

///|
test "interpolation lambda expands returned templates and escapes output" {
  let context = Value::object({
    "planet": Value::string("<Earth>"),
    "lambda": Value::interpolation_lambda(fn() { "{{{planet}}}" }),
  })
  inspect(
    render("Hello {{lambda}} / {{{lambda}}}", context),
    content="Hello &lt;Earth&gt; / <Earth>",
  )
}

///|
test "section lambda receives raw source and expands returned templates" {
  let context = Value::object({
    "planet": Value::string("Earth"),
    "lambda": Value::section_lambda(fn(text) { text + "{{planet}}" + text }),
  })
  inspect(render("<{{#lambda}}-{{/lambda}}>", context), content="<-Earth->")
}

///|
test "section lambda honors active delimiters" {
  let context = Value::object({
    "planet": Value::string("Earth"),
    "lambda": Value::section_lambda(fn(text) {
      text + "{{planet}} => |planet|" + text
    }),
  })
  inspect(
    render("{{= | | =}}<|#lambda|-|/lambda|>", context),
    content="<-{{planet}} => Earth->",
  )
}

///|
test "interpolation lambdas are invoked for every reference" {
  let calls = [0]
  let context = Value::object({
    "lambda": Value::interpolation_lambda(fn() {
      calls[0] = calls[0] + 1
      calls[0].to_string()
    }),
  })
  inspect(
    render("{{lambda}} == {{{lambda}}} == {{lambda}}", context),
    content="1 == 2 == 3",
  )
}

///|
test "value_to_string handles string values" {
  let actual = value_to_string(Value::string("moonbit"))
  inspect(actual, content="moonbit")
}
