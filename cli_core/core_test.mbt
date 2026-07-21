///|
// Exercises the non-IO CLI decision layer independently of the main package.
fn has_diagnostic_tip(message : String) -> Bool {
  match diagnostic_tip(message) {
    Some(_) => true
    None => false
  }
}

///|
test "CLI core parses assignments without discarding equals signs" {
  match parse_assignment("name=Moon=Bit") {
    Some((name, value)) => {
      inspect(name, content="name")
      inspect(value, content="Moon=Bit")
    }
    None => fail("expected a valid assignment")
  }
  inspect(parse_assignment("missing-separator") is None, content="true")
}

///|
test "CLI core deduplicates diagnostics in first-seen order" {
  let actual = unique_diagnostics([
    "second", "first", "second", "third", "first",
  ])
  inspect(actual.length(), content="3")
  inspect(actual[0], content="second")
  inspect(actual[1], content="first")
  inspect(actual[2], content="third")
}

///|
test "CLI core provides actionable tips for every supported failure family" {
  let messages = [
    "invalid --var assignment", "invalid --partial assignment", "missing partial: footer",
    "missing variable: owner", "invalid JSON context", "invalid partials JSON", "failed to read template file",
    "failed to read JSON context file", "failed to read partials file", "failed to read bundle manifest file",
    "file IO is only supported when running the CLI with --target js", "invalid bundle manifest: bad files",
    "unsupported bundle report format", "parent traversal is not allowed", "invalid-output-path",
    "unterminated section: user", "partial depth limit exceeded: 64",
  ]
  for message in messages {
    inspect(has_diagnostic_tip(message), content="true")
  }
  inspect(has_diagnostic_tip("unknown diagnostic"), content="false")
}

///|
test "CLI core composes defaults, output paths, and partial overrides" {
  inspect(default_template().contains("{{name}}"), content="true")
  inspect(join_output_path("", "README.md"), content="README.md")
  inspect(
    join_output_path("generated", "src/main.mbt"),
    content="generated/src/main.mbt",
  )
  let merged = merge_partial_maps({ "footer": "base", "header": "header" }, {
    "footer": "override",
    "card": "card",
  })
  inspect(merged.length(), content="3")
  inspect(merged.get_or_default("footer", ""), content="override")
  inspect(merged.get_or_default("header", ""), content="header")
  inspect(merged.get_or_default("card", ""), content="card")
}

///|
test "CLI core formats supported bundle reports and rejects unknown formats" {
  let bundle = @src.TemplateBundle::new(
    [@src.TemplateFile::new("README.md", "# {{name}}")],
    {},
  )
  let context = @src.Value::object({ "name": @src.Value::string("starter") })
  let result = @src.render_template_bundle_checked(
    bundle,
    context,
    @src.RenderOptions::default(),
  )
  match build_bundle_report_output("json", "starter", result) {
    Some((format, content)) => {
      inspect(format, content="json")
      inspect(content.contains("\"starter\""), content="true")
    }
    None => fail("expected JSON report")
  }
  match build_bundle_report_output("markdown", "starter", result) {
    Some((format, content)) => {
      inspect(format, content="markdown")
      inspect(content.contains("# Bundle Render Report"), content="true")
    }
    None => fail("expected Markdown report")
  }
  inspect(
    build_bundle_report_output("xml", "starter", result) is None,
    content="true",
  )
  let validation = @src.validate_template_bundle(bundle)
  inspect(
    build_bundle_plan_output("starter", result, validation).contains(
      "# Bundle Generation Plan",
    ),
    content="true",
  )
}

///|
test "CLI core gives stable warning and error validation diagnostics" {
  let validation = @src.validate_template_bundle(
    @src.TemplateBundle::new(
      [
        @src.TemplateFile::new("empty.txt", ""),
        @src.TemplateFile::new("../secret.txt", "unsafe"),
      ],
      {},
    ),
  )
  let messages : Array[String] = []
  for issue in validation.issues {
    messages.push(validation_issue_diagnostic(issue))
  }
  inspect(messages.length() >= 2, content="true")
  inspect(messages.join("\n").contains("bundle warning"), content="true")
  inspect(messages.join("\n").contains("bundle error"), content="true")
}

///|
test "CLI core centralizes output blocking decisions" {
  inspect(should_block_single_template(false, 3), content="false")
  inspect(should_block_single_template(true, 0), content="false")
  inspect(should_block_single_template(true, 1), content="true")
  inspect(should_block_bundle(false, 0, false), content="false")
  inspect(should_block_bundle(true, 0, false), content="true")
  inspect(should_block_bundle(false, 1, false), content="true")
  inspect(should_block_bundle(false, 0, true), content="true")
}
