///|
pub fn parse(template : String) -> ParseResult {
  parse_template(template)
}

///|
pub fn prepare(
  template : String,
  partials : Map[String, String],
) -> PreparedTemplate {
  prepare_template(template, partials)
}

///|
pub fn render(template : String, context : Value) -> String {
  render_string(template, context)
}

///|
pub fn render_with_partials(
  template : String,
  context : Value,
  partials : Map[String, String],
) -> String {
  render_string_with_partials(template, context, partials)
}

///|
pub fn render_checked(template : String, context : Value) -> RenderResult {
  render_string_checked(template, context)
}

///|
pub fn render_with_partials_checked(
  template : String,
  context : Value,
  partials : Map[String, String],
) -> RenderResult {
  render_string_with_partials_checked(template, context, partials)
}

///|
pub fn render_checked_with_options(
  template : String,
  context : Value,
  options : RenderOptions,
) -> RenderResult {
  render_string_with_partials_checked_with_options(
    template,
    context,
    {},
    options,
  )
}

///|
pub fn render_with_partials_checked_with_options(
  template : String,
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> RenderResult {
  render_string_with_partials_checked_with_options(
    template, context, partials, options,
  )
}

///|
pub fn render_prepared(prepared : PreparedTemplate, context : Value) -> String {
  render_prepared_template(prepared, context)
}

///|
pub fn render_prepared_checked(
  prepared : PreparedTemplate,
  context : Value,
) -> RenderResult {
  render_prepared_template_checked(prepared, context)
}

///|
pub fn render_prepared_checked_with_options(
  prepared : PreparedTemplate,
  context : Value,
  options : RenderOptions,
) -> RenderResult {
  render_prepared_template_checked_with_options(prepared, context, options)
}

///|
pub fn parse_json_context(input : String) -> Value raise @json.ParseError {
  value_from_json_string(input)
}

///|
pub fn parse_json_partials_checked(
  input : String,
) -> Result[Map[String, String], String] {
  let parsed = @json.parse(input) catch {
    err => return Err("invalid partials JSON: " + err.to_string())
  }
  let partials : Map[String, String] = @json.from_json(parsed) catch {
    err => return Err("invalid partials JSON: " + err.to_string())
  }
  Ok(partials)
}

///|
pub fn render_json(
  template : String,
  context_json : String,
) -> String raise @json.ParseError {
  render(template, parse_json_context(context_json))
}

///|
pub fn render_json_with_partials(
  template : String,
  context_json : String,
  partials : Map[String, String],
) -> String raise @json.ParseError {
  render_with_partials(template, parse_json_context(context_json), partials)
}

///|
pub fn render_json_checked(
  template : String,
  context_json : String,
  partials : Map[String, String],
) -> RenderResult {
  render_json_checked_with_options(
    template,
    context_json,
    partials,
    RenderOptions::default(),
  )
}

///|
pub fn render_json_checked_with_options(
  template : String,
  context_json : String,
  partials : Map[String, String],
  options : RenderOptions,
) -> RenderResult {
  let context = parse_json_context(context_json) catch {
    err =>
      return {
        output: "",
        errors: ["invalid JSON context: " + err.to_string()],
        missing_variables: [],
      }
  }
  render_with_partials_checked_with_options(
    template, context, partials, options,
  )
}

///|
pub fn render_prepared_json_checked(
  prepared : PreparedTemplate,
  context_json : String,
) -> RenderResult {
  render_prepared_json_checked_with_options(
    prepared,
    context_json,
    RenderOptions::default(),
  )
}

///|
pub fn render_prepared_json_checked_with_options(
  prepared : PreparedTemplate,
  context_json : String,
  options : RenderOptions,
) -> RenderResult {
  let context = parse_json_context(context_json) catch {
    err =>
      return {
        output: "",
        errors: ["invalid JSON context: " + err.to_string()],
        missing_variables: [],
      }
  }
  render_prepared_checked_with_options(prepared, context, options)
}

///|
pub fn render_json_bundle_checked(
  template : String,
  context_json : String,
  partials_json : String,
) -> RenderResult {
  render_json_bundle_checked_with_options(
    template,
    context_json,
    partials_json,
    RenderOptions::default(),
  )
}

///|
pub fn render_json_bundle_checked_with_options(
  template : String,
  context_json : String,
  partials_json : String,
  options : RenderOptions,
) -> RenderResult {
  let partials_result = parse_json_partials_checked(partials_json)
  let partials = match partials_result {
    Ok(partials) => partials
    Err(message) =>
      return { output: "", errors: [message], missing_variables: [] }
  }
  render_json_checked_with_options(template, context_json, partials, options)
}
