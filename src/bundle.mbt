///|
pub struct TemplateFile {
  path : String
  template : String
}

///|
pub struct TemplateBundle {
  files : Array[TemplateFile]
  partials : Map[String, String]
}

///|
pub struct GeneratedFile {
  path : String
  output : String
  errors : Array[String]
  missing_variables : Array[String]
}

///|
pub struct BundleRenderResult {
  files : Array[GeneratedFile]
  errors : Array[String]
  missing_variables : Array[String]
}

///|
pub struct PreparedTemplateFile {
  path_template : String
  path_nodes : Array[Node]
  path_errors : Array[String]
  template_nodes : Array[Node]
  template_errors : Array[String]
}

///|
pub struct PreparedTemplateBundle {
  files : Array[PreparedTemplateFile]
  partials : PreparedPartials
}

///|
pub fn TemplateFile::new(path : String, template : String) -> TemplateFile {
  { path, template }
}

///|
pub fn TemplateBundle::new(
  files : Array[TemplateFile],
  partials : Map[String, String],
) -> TemplateBundle {
  { files, partials }
}

///|
pub fn PreparedTemplateFile::new(
  path : String,
  template : String,
) -> PreparedTemplateFile {
  let path_parsed = parse_template(path)
  let template_parsed = parse_template(template)
  {
    path_template: path,
    path_nodes: path_parsed.nodes,
    path_errors: path_parsed.errors,
    template_nodes: template_parsed.nodes,
    template_errors: template_parsed.errors,
  }
}

///|
pub fn PreparedTemplateBundle::new(
  bundle : TemplateBundle,
) -> PreparedTemplateBundle {
  let files : Array[PreparedTemplateFile] = []
  for file in bundle.files {
    files.push(PreparedTemplateFile::new(file.path, file.template))
  }
  { files, partials: prepare_partials(bundle.partials) }
}

///|
pub fn prepare_template_bundle(
  bundle : TemplateBundle,
) -> PreparedTemplateBundle {
  PreparedTemplateBundle::new(bundle)
}

///|
fn record_unique_name(
  items : Array[String],
  seen : Map[String, Bool],
  name : String,
) -> Unit {
  if seen.get_or_default(name, false) {
    return
  }
  seen[name] = true
  items.push(name)
}

///|
fn append_unique_names(
  target : Array[String],
  seen : Map[String, Bool],
  incoming : Array[String],
) -> Unit {
  for name in incoming {
    record_unique_name(target, seen, name)
  }
}

///|
fn build_generated_file(
  rendered_path : RenderResult,
  rendered_output : RenderResult,
  fallback_path : String,
) -> GeneratedFile {
  let errors : Array[String] = []
  for error in rendered_path.errors {
    errors.push("path template: " + error)
  }
  match normalize_bundle_path(rendered_path.output) {
    Ok(_) => ()
    Err(message) => errors.push("rendered output path: " + message)
  }
  for error in rendered_output.errors {
    errors.push(error)
  }
  let missing_variables : Array[String] = []
  let missing_variable_set : Map[String, Bool] = {}
  append_unique_names(
    missing_variables,
    missing_variable_set,
    rendered_path.missing_variables,
  )
  append_unique_names(
    missing_variables,
    missing_variable_set,
    rendered_output.missing_variables,
  )
  let path = if rendered_path.output == "" {
    fallback_path
  } else {
    rendered_path.output
  }
  { path, output: rendered_output.output, errors, missing_variables }
}

///|
pub fn render_template_file_checked(
  file : TemplateFile,
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> GeneratedFile {
  let path_result = render_with_partials_checked_with_options(
    file.path,
    context,
    partials,
    options,
  )
  let output_result = render_with_partials_checked_with_options(
    file.template,
    context,
    partials,
    options,
  )
  build_generated_file(path_result, output_result, file.path)
}

///|
pub fn render_prepared_template_file_checked(
  file : PreparedTemplateFile,
  context : Value,
  partials : PreparedPartials,
  options : RenderOptions,
) -> GeneratedFile {
  let path_prepared = PreparedTemplate::{
    nodes: file.path_nodes,
    errors: file.path_errors,
    partials,
  }
  let template_prepared = PreparedTemplate::{
    nodes: file.template_nodes,
    errors: file.template_errors,
    partials,
  }
  let path_result = render_prepared_template_checked_with_options(
    path_prepared, context, options,
  )
  let output_result = render_prepared_template_checked_with_options(
    template_prepared, context, options,
  )
  build_generated_file(path_result, output_result, file.path_template)
}

///|
pub fn render_template_bundle_checked(
  bundle : TemplateBundle,
  context : Value,
  options : RenderOptions,
) -> BundleRenderResult {
  let prepared = prepare_template_bundle(bundle)
  render_prepared_template_bundle_checked(prepared, context, options)
}

///|
pub fn render_prepared_template_bundle_checked(
  bundle : PreparedTemplateBundle,
  context : Value,
  options : RenderOptions,
) -> BundleRenderResult {
  let rendered_files : Array[GeneratedFile] = []
  let bundle_errors : Array[String] = []
  let bundle_missing_variables : Array[String] = []
  let bundle_missing_variable_set : Map[String, Bool] = {}
  for file in bundle.files {
    let rendered = render_prepared_template_file_checked(
      file,
      context,
      bundle.partials,
      options,
    )
    for error in rendered.errors {
      bundle_errors.push(rendered.path + ": " + error)
    }
    for name in rendered.missing_variables {
      record_unique_name(
        bundle_missing_variables, bundle_missing_variable_set, name,
      )
    }
    rendered_files.push(rendered)
  }
  {
    files: rendered_files,
    errors: bundle_errors,
    missing_variables: bundle_missing_variables,
  }
}

///|
pub fn render_template_bundle_json_checked(
  bundle : TemplateBundle,
  context_json : String,
  options : RenderOptions,
) -> BundleRenderResult {
  let context = parse_json_context(context_json) catch {
    err =>
      return {
        files: [],
        errors: ["invalid JSON context: " + err.to_string()],
        missing_variables: [],
      }
  }
  render_template_bundle_checked(bundle, context, options)
}

///|
pub fn render_prepared_template_bundle_json_checked(
  bundle : PreparedTemplateBundle,
  context_json : String,
  options : RenderOptions,
) -> BundleRenderResult {
  let context = parse_json_context(context_json) catch {
    err =>
      return {
        files: [],
        errors: ["invalid JSON context: " + err.to_string()],
        missing_variables: [],
      }
  }
  render_prepared_template_bundle_checked(bundle, context, options)
}

///|
pub fn bundle_has_issues(result : BundleRenderResult) -> Bool {
  result.errors.length() > 0 || result.missing_variables.length() > 0
}
