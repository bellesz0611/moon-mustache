///|
fn first_value(matches : @argparse.Matches, name : String) -> String? {
  match matches.values.get(name) {
    Some(values) => if values.length() > 0 { Some(values[0]) } else { None }
    None => None
  }
}

///|
fn flag_enabled(matches : @argparse.Matches, name : String) -> Bool {
  matches.flags.get_or_default(name, false)
}

///|
fn push_all(target : Array[String], incoming : Array[String]) -> Unit {
  for item in incoming {
    target.push(item)
  }
}

///|
fn parse_assignment(entry : String) -> (String, String)? {
  match entry.split_once("=") {
    Some((name, value)) => Some((name.to_owned(), value.to_owned()))
    None => None
  }
}

///|
fn unique_diagnostics(errors : Array[String]) -> Array[String] {
  let unique : Array[String] = []
  let seen : Map[String, Bool] = {}
  for error in errors {
    if !seen.get_or_default(error, false) {
      seen[error] = true
      unique.push(error)
    }
  }
  unique
}

///|
fn diagnostic_tip(message : String) -> String? {
  if message.contains("invalid --var assignment") {
    Some(
      "Use --var key=value. Dotted keys such as user.name=Alice are supported.",
    )
  } else if message.contains("invalid --partial assignment") {
    Some(
      "Use --partial name=template, or load multiple partials with --partials-json-file.",
    )
  } else if message.contains("missing partial:") {
    Some(
      "Add the partial inline with --partial name=..., or load a JSON partial map with --partials-json-file.",
    )
  } else if message.contains("missing variable:") {
    Some(
      "Provide the value through --var, --json, --json-file, or the selected bundle profile context.",
    )
  } else if message.contains("invalid JSON context") {
    Some(
      "Check shell quoting first. On PowerShell, --json-base64 is often the easiest way to pass JSON safely.",
    )
  } else if message.contains("invalid partials JSON") {
    Some(
      "The partials file must be a JSON object that maps partial names to template strings.",
    )
  } else if message.contains("failed to read template file") ||
    message.contains("failed to read JSON context file") ||
    message.contains("failed to read partials file") ||
    message.contains("failed to read bundle manifest file") {
    Some(
      "Double-check the path, and use --target js for file-backed CLI flows.",
    )
  } else if message.contains(
      "file IO is only supported when running the CLI with --target js",
    ) {
    Some(
      "Re-run the command as moon run --target js cli ... when reading or writing files.",
    )
  } else if message.contains("invalid bundle manifest:") {
    Some(
      "Validate the manifest shape first, or print the sample manifest with --print-sample-manifest.",
    )
  } else if message.contains("unsupported bundle report format") {
    Some("Use --bundle-report-format markdown or --bundle-report-format json.")
  } else if message.contains("parent traversal") ||
    message.contains("invalid-output-path") {
    Some(
      "Bundle output paths must stay inside the generated project tree and cannot use parent traversal segments.",
    )
  } else if message.contains("unterminated section:") {
    Some(
      "Every {{#name}} or {{^name}} block needs a matching closing tag such as {{/name}}.",
    )
  } else if message.contains("partial depth limit exceeded:") {
    Some(
      "This usually means recursive partial expansion. Check whether a partial includes itself directly or indirectly.",
    )
  } else {
    None
  }
}

///|
fn print_diagnostics(errors : Array[String]) -> Unit {
  let unique = unique_diagnostics(errors)
  if unique.length() == 0 {
    return
  }
  println(
    "moon-mustache found " + unique.length().to_string() + " diagnostic(s):",
  )
  for error in unique {
    println("- " + error)
    match diagnostic_tip(error) {
      Some(tip) => println("  tip: " + tip)
      None => ()
    }
  }
  println("")
}

///|
fn print_cli_examples() -> Unit {
  println("Moon Mustache examples")
  println("")
  println("Inline render")
  println("  moon run cli --template \"Hello {{name}}\" --var name=MoonBit")
  println("")
  println("JSON context")
  println(
    "  moon run cli --json \"{\\\"project\\\":{\\\"name\\\":\\\"moon-mustache\\\"}}\" --template \"{{project.name}}\"",
  )
  println("")
  println("File-backed render (js target)")
  println(
    "  moon run --target js cli --template-file examples/files/template.mustache --json-file examples/files/context.json --partials-json-file examples/files/partials.json",
  )
  println("")
  println("Bundle manifest validation without writing files")
  println(
    "  moon run --target js cli --bundle-manifest-file examples/bundle/manifest.json --bundle-profile dev --json-file examples/bundle/context.json --bundle-check-only --bundle-validation-file out_bundle_check/validation.md --bundle-plan-file out_bundle_check/plan.md",
  )
  println("")
  println("Scan template variables")
  println(
    "  moon run cli --template \"{{#user}}{{name}}{{/user}}{{> footer}}\" --scan",
  )
  println("")
}

///|
fn print_quickstart_banner() -> Unit {
  println("Moon Mustache quick start")
  println("")
  println("Try one of these next:")
  println("  moon run cli --examples")
  println("  moon run showcase")
  println("  moon run scenario_report")
  println("  moon run official_spec_report")
  println("")
  println("Sample output from the built-in demo template:")
  println("")
}

///|
fn parse_json_input(input : String) -> (@src.Value, Array[String]) {
  (@src.parse_json_context(input), ([] : Array[String])) catch {
    err =>
      (@src.Value::empty_object(), ["invalid JSON context: " + err.to_string()])
  }
}

///|
fn build_template(matches : @argparse.Matches) -> (String, Array[String]) {
  match first_value(matches, "template-file") {
    Some(path) =>
      match read_text_file(path) {
        Ok(content) => (content, [])
        Err(message) => ("", ["failed to read template file: " + message])
      }
    None =>
      match first_value(matches, "template") {
        Some(value) => (value, [])
        None => (default_template(), [])
      }
  }
}

///|
fn has_explicit_context(matches : @argparse.Matches) -> Bool {
  first_value(matches, "json-file") is Some(_) ||
  first_value(matches, "json-base64") is Some(_) ||
  first_value(matches, "json") is Some(_) ||
  matches.values.get("var") is Some(_)
}

///|
fn build_base_context(
  matches : @argparse.Matches,
) -> (@src.Value, Array[String]) {
  match first_value(matches, "json-file") {
    Some(path) =>
      match read_text_file(path) {
        Ok(content) => return parse_json_input(content)
        Err(message) =>
          return (
            @src.Value::empty_object(),
            ["failed to read JSON context file: " + message],
          )
      }
    None => ()
  }
  match first_value(matches, "json-base64") {
    Some(encoded) => {
      let decoded = @base64.decode(encoded) catch {
        _ =>
          return (@src.Value::empty_object(), ["invalid Base64 JSON context"])
      }
      let json_input = @utf8.decode(decoded) catch {
        _ => return (@src.Value::empty_object(), ["invalid UTF-8 JSON context"])
      }
      return parse_json_input(json_input)
    }
    None => ()
  }
  match first_value(matches, "json") {
    Some(input) => parse_json_input(input)
    None => (@src.Value::empty_object(), [])
  }
}

///|
fn build_context_from_assignments(
  matches : @argparse.Matches,
) -> (@src.Value, Array[String]) {
  let entries : Array[(String, String)] = []
  let errors : Array[String] = []
  match matches.values.get("var") {
    Some(values) =>
      for entry in values {
        match parse_assignment(entry) {
          Some((name, value)) => entries.push((name, value))
          None =>
            errors.push(
              "invalid --var assignment (expected key=value): " + entry,
            )
        }
      }
    None => ()
  }
  let (context, parse_errors) = @src.object_from_string_entries(entries)
  push_all(errors, parse_errors)
  (context, errors)
}

///|
fn build_context(matches : @argparse.Matches) -> (@src.Value, Array[String]) {
  let (base_context, base_errors) = build_base_context(matches)
  let (override_context, override_errors) = build_context_from_assignments(
    matches,
  )
  let merged_context = @src.merge_values(base_context, override_context)
  let merged_errors = base_errors.copy()
  for error in override_errors {
    merged_errors.push(error)
  }
  if !has_explicit_context(matches) {
    let fallback : Map[String, @src.Value] = {
      "name": @src.Value::string("MoonBit"),
      "role": @src.Value::string("template engine"),
    }
    return (@src.Value::object(fallback), merged_errors)
  }
  (merged_context, merged_errors)
}

///|
fn build_partials(
  matches : @argparse.Matches,
) -> (Map[String, String], Array[String]) {
  let partials : Map[String, String] = {}
  let errors : Array[String] = []
  match first_value(matches, "partials-json-file") {
    Some(path) =>
      match read_text_file(path) {
        Ok(content) =>
          match @src.parse_json_partials_checked(content) {
            Ok(file_partials) =>
              for name, template in file_partials {
                partials[name] = template
              }
            Err(message) => errors.push(message)
          }
        Err(message) => errors.push("failed to read partials file: " + message)
      }
    None => ()
  }
  match matches.values.get("partial") {
    Some(values) =>
      for entry in values {
        match parse_assignment(entry) {
          Some((name, value)) => partials[name] = value
          None =>
            errors.push(
              "invalid --partial assignment (expected name=template): " + entry,
            )
        }
      }
    None => ()
  }
  (partials, errors)
}

///|
fn build_render_options(matches : @argparse.Matches) -> @src.RenderOptions {
  if flag_enabled(matches, "strict-missing") {
    @src.RenderOptions::strict()
  } else {
    @src.RenderOptions::default()
  }
}

///|
fn default_template() -> String {
  "Project {{name}} builds a {{role}}.\n{{> footer}}"
}

///|
fn effective_argv() -> ArrayView[String] {
  let args = @env.args()
  if args.length() > 2 && args[1].strip_suffix(".js") is Some(_) {
    args[2:]
  } else if args.length() > 1 {
    args[1:]
  } else {
    []
  }
}

///|
fn print_sample_manifest() -> Unit {
  println(@src.sample_bundle_manifest_json())
}

///|
fn print_scan_result(result : @src.TemplateScanResult) -> Unit {
  let current_context_usage = if result.uses_current_context {
    "yes"
  } else {
    "no"
  }
  let dotted_name_usage = if result.uses_dotted_names { "yes" } else { "no" }
  println("Template scan summary")
  println("")
  println("Data names (" + result.data_names.length().to_string() + ")")
  for name in result.data_names {
    println("- " + name)
  }
  println("")
  println("Partial names (" + result.partial_names.length().to_string() + ")")
  for name in result.partial_names {
    println("- " + name)
  }
  println("")
  println("Reference count: " + result.references.length().to_string())
  println("Uses current context: " + current_context_usage)
  println("Uses dotted names: " + dotted_name_usage)
  println("Delimiter changes: " + result.delimiter_change_count.to_string())
  if result.parse_errors.length() > 0 {
    println("")
    println("Parse diagnostics")
    for error in result.parse_errors {
      println("- " + error)
    }
  }
}

///|
fn bundle_manifest_enabled(matches : @argparse.Matches) -> Bool {
  first_value(matches, "bundle-manifest-file") is Some(_)
}

///|
fn merge_partial_maps(
  base : Map[String, String],
  incoming : Map[String, String],
) -> Map[String, String] {
  let merged : Map[String, String] = {}
  for name, template in base {
    merged[name] = template
  }
  for name, template in incoming {
    merged[name] = template
  }
  merged
}

///|
fn join_output_path(root : String, relative : String) -> String {
  if root == "" {
    relative
  } else {
    root + "/" + relative
  }
}

///|
fn print_generated_file(file : @src.GeneratedFile) -> Unit {
  println("== " + file.path + " ==")
  println(file.output)
  println("")
}

///|
fn build_bundle_manifest(
  matches : @argparse.Matches,
) -> (@src.BundleManifest?, Array[String]) {
  match first_value(matches, "bundle-manifest-file") {
    Some(path) =>
      match read_text_file(path) {
        Ok(content) =>
          match @src.parse_bundle_manifest_json(content) {
            Ok(manifest) => (Some(manifest), [])
            Err(message) => (None, ["invalid bundle manifest: " + message])
          }
        Err(message) =>
          (None, ["failed to read bundle manifest file: " + message])
      }
    None => (None, [])
  }
}

///|
fn build_bundle_report_output(
  format : String,
  bundle_name : String,
  result : @src.BundleRenderResult,
) -> (String, String)? {
  if format == "json" {
    Some(("json", @src.format_bundle_result_json(bundle_name, result)))
  } else if format == "markdown" {
    Some(("markdown", @src.format_bundle_result_markdown(bundle_name, result)))
  } else {
    None
  }
}

///|
fn build_bundle_plan_output(
  bundle_name : String,
  render_result : @src.BundleRenderResult,
  validation_result : @src.BundleValidationResult,
) -> String {
  @src.format_bundle_plan_markdown(
    @src.build_bundle_plan(bundle_name, render_result, validation_result),
  )
}

///|
fn validation_issue_diagnostic(issue : @src.BundleValidationIssue) -> String {
  let severity = match issue.severity {
    Error => "error"
    Warning => "warning"
  }
  "bundle " +
  severity +
  " [" +
  issue.code +
  "] " +
  issue.target +
  ": " +
  issue.message
}

///|
fn handle_bundle_mode(
  matches : @argparse.Matches,
  context : @src.Value,
  context_errors : Array[String],
  partials : Map[String, String],
  partial_errors : Array[String],
  render_options : @src.RenderOptions,
) -> Unit {
  let (manifest_opt, manifest_errors) = build_bundle_manifest(matches)
  let all_errors = context_errors.copy()
  push_all(all_errors, partial_errors)
  push_all(all_errors, manifest_errors)
  let manifest = match manifest_opt {
    Some(value) => value
    None => {
      print_diagnostics(all_errors)
      return
    }
  }
  let validation_result = @src.validate_bundle_manifest(manifest)
  for issue in validation_result.issues {
    all_errors.push(validation_issue_diagnostic(issue))
  }
  let profile_name = match first_value(matches, "bundle-profile") {
    Some(value) => value
    None => ""
  }
  let resolved = match
    @src.resolve_bundle_manifest_profile(manifest, context, profile_name~) {
    Ok(value) => value
    Err(message) => {
      print_diagnostics([message])
      return
    }
  }
  let merged_partials = merge_partial_maps(resolved.bundle.partials, partials)
  let final_bundle = @src.TemplateBundle::new(
    resolved.bundle.files,
    merged_partials,
  )
  let result = @src.render_template_bundle_checked(
    final_bundle,
    resolved.context,
    render_options,
  )
  for error in result.errors {
    all_errors.push(error)
  }
  for name in result.missing_variables {
    all_errors.push("missing variable: " + name)
  }
  if all_errors.length() > 0 {
    print_diagnostics(all_errors)
    if flag_enabled(matches, "strict") ||
      @src.validation_has_errors(validation_result) {
      println(
        "No bundle files were written because strict mode or validation errors blocked output.",
      )
      return
    }
  }
  if !flag_enabled(matches, "bundle-check-only") {
    match first_value(matches, "bundle-output-dir") {
      Some(root) =>
        for file in result.files {
          let path = join_output_path(root, file.path)
          match write_text_file(path, file.output) {
            Ok(_) => ()
            Err(message) =>
              print_diagnostics([
                "failed to write bundle file `" + path + "`: " + message,
              ])
          }
        }
      None =>
        for file in result.files {
          print_generated_file(file)
        }
    }
  }
  match first_value(matches, "bundle-report-file") {
    Some(path) => {
      let format = match first_value(matches, "bundle-report-format") {
        Some(value) => value
        None => "markdown"
      }
      match build_bundle_report_output(format, manifest.name, result) {
        Some((_, content)) =>
          match write_text_file(path, content) {
            Ok(_) => println("Wrote bundle report to " + path)
            Err(message) =>
              print_diagnostics(["failed to write bundle report: " + message])
          }
        None => print_diagnostics(["unsupported bundle report format"])
      }
    }
    None => ()
  }
  match first_value(matches, "bundle-validation-file") {
    Some(path) =>
      match
        write_text_file(
          path,
          @src.format_validation_report_markdown(
            manifest.name,
            validation_result,
          ),
        ) {
        Ok(_) => println("Wrote bundle validation report to " + path)
        Err(message) =>
          print_diagnostics([
            "failed to write bundle validation report: " + message,
          ])
      }
    None => ()
  }
  match first_value(matches, "bundle-plan-file") {
    Some(path) =>
      match
        write_text_file(
          path,
          build_bundle_plan_output(manifest.name, result, validation_result),
        ) {
        Ok(_) => println("Wrote bundle generation plan to " + path)
        Err(message) =>
          print_diagnostics([
            "failed to write bundle generation plan: " + message,
          ])
      }
    None => ()
  }
  if flag_enabled(matches, "bundle-check-only") {
    println("Bundle check completed without writing generated files.")
  }
}

///|
fn handle_single_template_mode(
  matches : @argparse.Matches,
  context : @src.Value,
  context_errors : Array[String],
  partials : Map[String, String],
  partial_errors : Array[String],
  render_options : @src.RenderOptions,
) -> Unit {
  let (template, template_errors) = build_template(matches)
  let resolved_partials = if partials.length() == 0 {
    { "footer": "Rendered by moon-mustache." }
  } else {
    partials
  }

  let result = @src.render_with_partials_checked_with_options(
    template, context, resolved_partials, render_options,
  )
  let all_errors = template_errors.copy()
  for error in context_errors {
    all_errors.push(error)
  }
  for error in partial_errors {
    all_errors.push(error)
  }
  for error in result.errors {
    all_errors.push(error)
  }
  for name in result.missing_variables {
    all_errors.push("missing variable: " + name)
  }

  if all_errors.length() > 0 {
    print_diagnostics(all_errors)
    if flag_enabled(matches, "strict") {
      println("No rendered output was produced because strict mode is enabled.")
      return
    }
  }

  match first_value(matches, "output") {
    Some(path) =>
      match write_text_file(path, result.output) {
        Ok(_) => println("Wrote rendered output to " + path)
        Err(message) =>
          print_diagnostics(["failed to write output file: " + message])
      }
    None => println(result.output)
  }
}

///|
fn main {
  let command = @argparse.Command(
    "moon-mustache",
    about="Render Mustache templates with MoonBit.",
    arg_required_else_help=false,
    options=[
      OptionArg(
        "template",
        short='t',
        long="template",
        about="Inline Mustache template to render.",
      ),
      OptionArg(
        "template-file",
        long="template-file",
        about="Read Mustache template content from a file.",
      ),
      OptionArg(
        "bundle-manifest-file",
        long="bundle-manifest-file",
        about="Read a JSON bundle manifest and render multiple files in one run.",
      ),
      OptionArg(
        "bundle-output-dir",
        long="bundle-output-dir",
        about="Write rendered bundle files under this directory.",
      ),
      OptionArg(
        "bundle-validation-file",
        long="bundle-validation-file",
        about="Write a Markdown validation report for the bundle manifest.",
      ),
      OptionArg(
        "bundle-plan-file",
        long="bundle-plan-file",
        about="Write a Markdown generation plan for the rendered bundle.",
      ),
      OptionArg(
        "bundle-profile",
        long="bundle-profile",
        about="Optional bundle profile defined inside the manifest.",
      ),
      OptionArg(
        "bundle-report-file",
        long="bundle-report-file",
        about="Write a bundle render report to a file.",
      ),
      OptionArg(
        "bundle-report-format",
        long="bundle-report-format",
        about="Bundle report format: markdown or json.",
      ),
      OptionArg(
        "json",
        long="json",
        about="Inline JSON object or array used as the template context.",
      ),
      OptionArg(
        "json-file",
        long="json-file",
        about="Read JSON context from a file.",
      ),
      OptionArg(
        "json-base64",
        long="json-base64",
        about="Base64-encoded JSON context, useful when shell quoting is inconvenient.",
      ),
      OptionArg(
        "partials-json-file",
        long="partials-json-file",
        about="Read partial templates from a JSON file that maps names to template strings.",
      ),
      OptionArg(
        "var",
        short='v',
        long="var",
        about="Template variable in key=value form. Repeatable and dotted paths are supported.",
        action=Append,
      ),
      OptionArg(
        "partial",
        short='p',
        long="partial",
        about="Partial template in name=template form. Repeatable.",
        action=Append,
      ),
      OptionArg(
        "output",
        short='o',
        long="output",
        about="Write rendered output to a file instead of stdout.",
      ),
    ],
    flags=[
      FlagArg(
        "strict",
        long="strict",
        about="Print diagnostics and skip output when rendering errors are found.",
      ),
      FlagArg(
        "strict-missing",
        long="strict-missing",
        about="Track missing variables as diagnostics for stricter template validation.",
      ),
      FlagArg(
        "bundle-check-only",
        long="bundle-check-only",
        about="Validate and render the bundle without writing generated files.",
      ),
      FlagArg(
        "examples",
        long="examples",
        about="Print a short cookbook of common CLI commands.",
      ),
      FlagArg(
        "scan",
        long="scan",
        about="Scan a template and print referenced data names, partials, and delimiter usage.",
      ),
      FlagArg(
        "print-default-template",
        long="print-default-template",
        about="Print the built-in demo template and exit.",
      ),
      FlagArg(
        "print-sample-manifest",
        long="print-sample-manifest",
        about="Print the sample bundle manifest JSON and exit.",
      ),
    ],
  )

  let matches = command.parse(argv=effective_argv()) catch {
    err => {
      println(err.to_string())
      return
    }
  }
  if flag_enabled(matches, "examples") {
    print_cli_examples()
    return
  }
  if flag_enabled(matches, "print-default-template") {
    println(default_template())
    return
  }
  if flag_enabled(matches, "print-sample-manifest") {
    print_sample_manifest()
    return
  }
  if effective_argv().length() == 0 {
    print_quickstart_banner()
  }
  if flag_enabled(matches, "scan") {
    let (template, template_errors) = build_template(matches)
    if template_errors.length() > 0 {
      print_diagnostics(template_errors)
      return
    }
    print_scan_result(@src.scan_template_references(template))
    return
  }
  let (context, context_errors) = build_context(matches)
  let (partials, partial_errors) = build_partials(matches)
  let render_options = build_render_options(matches)
  if bundle_manifest_enabled(matches) {
    handle_bundle_mode(
      matches, context, context_errors, partials, partial_errors, render_options,
    )
  } else {
    handle_single_template_mode(
      matches, context, context_errors, partials, partial_errors, render_options,
    )
  }
}
