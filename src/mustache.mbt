pub fn parse(template : String) -> ParseResult {
  parse_template(template)
}

pub fn render(template : String, context : Value) -> String {
  render_string(template, context)
}
