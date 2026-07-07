///|
pub struct ScenarioResult {
  name : String
  description : String
  passed : Bool
  summary : String
}

///|
fn build_demo_context() -> Value {
  let project = Value::object({
    "name": Value::string("moon-mustache"),
    "port": Value::number(8080),
    "owner": Value::string("Alice"),
  })
  Value::object({
    "project": project,
    "features": Value::array([
      Value::string("bundle manifests"),
      Value::string("spec reports"),
      Value::string("CLI diagnostics"),
    ]),
    "users": Value::array([
      Value::object({
        "name": Value::string("Alice"),
        "role": Value::string("maintainer"),
      }),
      Value::object({
        "name": Value::string("Bob"),
        "role": Value::string("reviewer"),
      }),
    ]),
  })
}

///|
fn scenario_plain_render() -> ScenarioResult {
  let output = render(
    "Project {{project.name}} listens on {{project.port}}",
    build_demo_context(),
  )
  {
    name: "plain_render",
    description: "Single-template rendering from nested MoonBit values.",
    passed: output == "Project moon-mustache listens on 8080",
    summary: output,
  }
}

///|
fn scenario_checked_missing_variables() -> ScenarioResult {
  let result = render_checked_with_options(
    "Hello {{project.name}} from {{missing}}",
    build_demo_context(),
    RenderOptions::strict(),
  )
  {
    name: "strict_missing",
    description: "Checked rendering collects missing variables without changing output semantics.",
    passed: result.missing_variables.length() == 1 &&
    result.missing_variables[0] == "missing",
    summary: "missing=" + result.missing_variables.length().to_string(),
  }
}

///|
fn scenario_bundle_render() -> ScenarioResult {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new(".env", "APP={{project.name}}"),
      TemplateFile::new("README.md", "# {{project.name}}"),
    ],
    {},
  )
  let result = render_template_bundle_checked(
    bundle,
    build_demo_context(),
    RenderOptions::default(),
  )
  {
    name: "bundle_render",
    description: "Bundle APIs render multiple generated files from one shared context.",
    passed: result.files.length() == 2 &&
    result.files[0].output == "APP=moon-mustache" &&
    result.files[1].output == "# moon-mustache",
    summary: "files=" + result.files.length().to_string(),
  }
}

///|
fn scenario_manifest_profile() -> ScenarioResult {
  let result = render_bundle_manifest_json_with_profile_checked(
    sample_bundle_manifest_json(),
    "{\"project\":{\"name\":\"moon-mustache\"},\"features\":[\"cli\"]}",
    RenderOptions::default(),
    profile_name="prod",
  )
  match result {
    Ok(bundle_result) => {
      let output = bundle_result.files[0].output
      {
        name: "manifest_profile",
        description: "Bundle manifests can switch behavior by profile for real scaffolding workflows.",
        passed: output.contains("APP_PORT=8080") &&
        output.contains("NETWORK=sample-net"),
        summary: output,
      }
    }
    Err(message) =>
      {
        name: "manifest_profile",
        description: "Bundle manifests can switch behavior by profile for real scaffolding workflows.",
        passed: false,
        summary: message,
      }
  }
}

///|
fn scenario_spec_report() -> ScenarioResult {
  let report = format_spec_report_markdown(run_all_spec_suites())
  {
    name: "spec_report",
    description: "Spec-style suites can be exported as a Markdown compatibility report.",
    passed: report.contains("| diagnostics | 4 | 4 | 0 |"),
    summary: "suites=" + all_spec_suites().length().to_string(),
  }
}

///|
fn scenario_bundle_report() -> ScenarioResult {
  let bundle = TemplateBundle::new(
    [TemplateFile::new("README.md", "# {{project.name}}")],
    {},
  )
  let result = render_template_bundle_checked(
    bundle,
    build_demo_context(),
    RenderOptions::default(),
  )
  let report = format_bundle_result_markdown("demo", result)
  {
    name: "bundle_report",
    description: "Bundle generation can emit a human-readable render report.",
    passed: report.contains("# Bundle Render Report") &&
    report.contains("## README.md"),
    summary: "report_chars=" + report.length().to_string(),
  }
}

///|
fn scenario_dotted_entry_builder() -> ScenarioResult {
  let (context, errors) = object_from_string_entries([
    ("project.name", "moon-mustache"),
    ("project.port", "8080"),
    ("enabled", "true"),
  ])
  let output = render("{{project.name}}/{{project.port}}/{{enabled}}", context)
  {
    name: "dotted_builder",
    description: "CLI-style dotted assignments build nested contexts automatically.",
    passed: errors.length() == 0 && output == "moon-mustache/8080/true",
    summary: output,
  }
}

///|
fn scenario_partial_recursion_guard() -> ScenarioResult {
  let partials = { "node": "{{> node}}" }
  let result = render_with_partials_checked_with_options(
    "{{> node}}",
    Value::empty_object(),
    partials,
    RenderOptions::default(),
  )
  let summary = if result.errors.length() > 0 {
    result.errors[0]
  } else {
    "no recursion error reported"
  }
  {
    name: "recursion_guard",
    description: "Recursive partial expansion is guarded by a depth limit.",
    passed: result.errors.length() > 0,
    summary,
  }
}

///|
fn scenario_bundle_validation_and_plan() -> ScenarioResult {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("deploy\\config.toml", "service={{project.name}}\n"),
      TemplateFile::new("README.md", "# {{project.name}}"),
    ],
    {},
  )
  let render_result = render_template_bundle_checked(
    bundle,
    build_demo_context(),
    RenderOptions::default(),
  )
  let validation_result = validate_template_bundle(bundle)
  let plan = build_bundle_plan("demo", render_result, validation_result)
  let report = format_bundle_plan_markdown(plan)
  {
    name: "bundle_validation_plan",
    description: "Bundles can be validated and converted into generation plans before any files are written.",
    passed: validation_error_count(validation_result) == 0 &&
    report.contains("deploy/config.toml"),
    summary: "files=" + plan.files.length().to_string(),
  }
}

///|
pub fn run_scenario_report() -> Array[ScenarioResult] {
  [
    scenario_plain_render(),
    scenario_checked_missing_variables(),
    scenario_bundle_render(),
    scenario_manifest_profile(),
    scenario_spec_report(),
    scenario_bundle_report(),
    scenario_bundle_validation_and_plan(),
    scenario_dotted_entry_builder(),
    scenario_partial_recursion_guard(),
  ]
}

///|
pub fn format_scenario_report_markdown(
  results : Array[ScenarioResult],
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# Moon Mustache Scenario Report\n\n")
  builder.write_string("| Scenario | Status | Description |\n")
  builder.write_string("| --- | --- | --- |\n")
  for result in results {
    builder.write_string("| ")
    builder.write_string(result.name)
    builder.write_string(" | ")
    builder.write_string(if result.passed { "pass" } else { "fail" })
    builder.write_string(" | ")
    builder.write_string(result.description)
    builder.write_string(" |\n")
  }
  builder.write_string("\n")
  for result in results {
    builder.write_string("## ")
    builder.write_string(result.name)
    builder.write_string("\n\n")
    builder.write_string("- status: ")
    builder.write_string(if result.passed { "pass" } else { "fail" })
    builder.write_string("\n")
    builder.write_string("- summary: `")
    builder.write_string(result.summary)
    builder.write_string("`\n\n")
  }
  builder.to_string()
}
