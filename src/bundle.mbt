pub struct TemplateFile {
  path : String
  template : String
}

pub struct TemplateBundle {
  files : Array[TemplateFile]
  partials : Map[String, String]
}

pub struct GeneratedFile {
  path : String
  output : String
  errors : Array[String]
  missing_variables : Array[String]
}

pub struct BundleRenderResult {
  files : Array[GeneratedFile]
  errors : Array[String]
  missing_variables : Array[String]
}

pub fn TemplateFile::new(path : String, template : String) -> TemplateFile {
  { path, template }
}

pub fn TemplateBundle::new(
  files : Array[TemplateFile],
  partials : Map[String, String],
) -> TemplateBundle {
  { files, partials }
}

fn record_unique_name(items : Array[String], name : String) -> Unit {
  for existing in items {
    if existing == name {
      return
    }
  }
  items.push(name)
}

pub fn render_template_file_checked(
  file : TemplateFile,
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> GeneratedFile {
  let result = render_with_partials_checked_with_options(
    file.template,
    context,
    partials,
    options,
  )
  {
    path: file.path,
    output: result.output,
    errors: result.errors,
    missing_variables: result.missing_variables,
  }
}

pub fn render_template_bundle_checked(
  bundle : TemplateBundle,
  context : Value,
  options : RenderOptions,
) -> BundleRenderResult {
  let rendered_files : Array[GeneratedFile] = []
  let bundle_errors : Array[String] = []
  let bundle_missing_variables : Array[String] = []
  for file in bundle.files {
    let rendered = render_template_file_checked(
      file,
      context,
      bundle.partials,
      options,
    )
    for error in rendered.errors {
      bundle_errors.push(rendered.path + ": " + error)
    }
    for name in rendered.missing_variables {
      record_unique_name(bundle_missing_variables, name)
    }
    rendered_files.push(rendered)
  }
  {
    files: rendered_files,
    errors: bundle_errors,
    missing_variables: bundle_missing_variables,
  }
}

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

pub fn bundle_has_issues(result : BundleRenderResult) -> Bool {
  result.errors.length() > 0 || result.missing_variables.length() > 0
}
