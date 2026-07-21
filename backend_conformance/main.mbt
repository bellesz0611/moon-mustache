///|
fn main {
  let escaped_context = @src.Value::object({
    "value": @src.Value::string("<tag>&\"'"),
  })
  println("escape=" + @src.render("{{value}}", escaped_context))

  let section_context = @src.Value::object({
    "category": @src.Value::string("core"),
    "items": @src.Value::array([
      @src.Value::object({ "name": @src.Value::string("scanner") }),
      @src.Value::object({ "name": @src.Value::string("renderer") }),
    ]),
  })
  println(
    "section=" +
    @src.render("{{#items}}{{category}}/{{name}};{{/items}}", section_context),
  )

  println(
    "partial=" +
    @src.render_with_partials(
      "{{> card}}",
      @src.Value::object({ "name": @src.Value::string("Moon") }),
      { "card": "<{{name}}>" },
    ),
  )

  println(
    "delimiter=" +
    @src.render(
      "{{=<% %>=}}<%name%>|<%#enabled%>on<%/enabled%><%^enabled%>off<%/enabled%>",
      @src.Value::object({
        "name": @src.Value::string("MoonBit"),
        "enabled": @src.Value::bool(true),
      }),
    ),
  )

  let strict = @src.render_checked_with_options(
    "Hello {{missing}}",
    @src.Value::empty_object(),
    @src.RenderOptions::strict(),
  )
  println("strict.output=[" + strict.output + "]")
  for error in strict.errors {
    println("strict.error=" + error)
  }
  for name in strict.missing_variables {
    println("strict.missing=" + name)
  }

  let malformed = @src.render_checked("{{#open}}", @src.Value::empty_object())
  for error in malformed.errors {
    println("parse.error=" + error)
  }
}
