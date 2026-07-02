test "escape_html handles reserved characters" {
  let actual = escape_html("<tag>&\"'")
  inspect(actual, content="&lt;tag&gt;&amp;&quot;&#39;")
}

test "render_string keeps plain text" {
  let actual = render("hello", Value::empty_object())
  inspect(actual, content="hello")
}

test "value_to_string handles string values" {
  let actual = value_to_string(Value::string("moonbit"))
  inspect(actual, content="moonbit")
}
