///|
pub struct SpecCase {
  name : String
  template : String
  data_json : String
  expected_output : String
  partials_json : String
  expected_errors : Array[String]
}

///|
pub struct SpecSuite {
  name : String
  cases : Array[SpecCase]
}

///|
fn spec_case(
  name : String,
  template : String,
  data_json : String,
  expected_output : String,
  partials_json? : String = "{}",
  expected_errors? : Array[String] = [],
) -> SpecCase {
  { name, template, data_json, expected_output, partials_json, expected_errors }
}

///|
pub fn interpolation_spec_suite() -> SpecSuite {
  {
    name: "interpolation",
    cases: [
      spec_case(
        "basic escaped interpolation", "Hello, {{subject}}!\n", "{\"subject\":\"world\"}",
        "Hello, world!\n",
      ),
      spec_case(
        "html escaping", "These characters should be HTML escaped: {{forbidden}}\n",
        "{\"forbidden\":\"& \\\" < >\"}", "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n",
      ),
      spec_case(
        "triple mustache", "HTML: {{{content}}}", "{\"content\":\"<b>MoonBit</b>\"}",
        "HTML: <b>MoonBit</b>",
      ),
      spec_case(
        "ampersand variable", "HTML: {{& content}}", "{\"content\":\"<i>Engine</i>\"}",
        "HTML: <i>Engine</i>",
      ),
      spec_case(
        "dotted names", "\"{{person.name}}\" == \"{{#person}}{{name}}{{/person}}\"\n",
        "{\"person\":{\"name\":\"Joe\"}}", "\"Joe\" == \"Joe\"\n",
      ),
      spec_case(
        "implicit iterator", "{{#list}}({{.}}){{/list}}", "{\"list\":[\"a\",\"b\",\"c\"]}",
        "(a)(b)(c)",
      ),
      spec_case(
        "missing variable renders empty string", "A{{missing}}B", "{}", "AB",
      ),
      spec_case(
        "numbers and booleans stringify", "{{count}}/{{enabled}}", "{\"count\":12,\"enabled\":true}",
        "12/true",
      ),
    ],
  }
}

///|
pub fn comment_spec_suite() -> SpecSuite {
  {
    name: "comments",
    cases: [
      spec_case(
        "inline comment removal", "12345{{! Comment Block! }}67890", "{}", "1234567890",
      ),
      spec_case(
        "multiline comment body", "A{{! hidden\ncomment }}B", "{}", "AB",
      ),
      spec_case(
        "comment keeps surrounding whitespace", "A {{! note }} B", "{}", "A  B",
      ),
    ],
  }
}

///|
pub fn section_spec_suite() -> SpecSuite {
  {
    name: "sections",
    cases: [
      spec_case(
        "object context", "\"{{#person}}{{name}}{{/person}}\"", "{\"person\":{\"name\":\"Jon\"}}",
        "\"Jon\"",
      ),
      spec_case(
        "falsey section skips body", "A{{#enabled}}B{{/enabled}}C", "{\"enabled\":false}",
        "AC",
      ),
      spec_case(
        "list iteration", "{{#users}}{{name}}/{{company}};{{/users}}", "{\"company\":\"OpenAI\",\"users\":[{\"name\":\"Alice\"},{\"name\":\"Bob\"}]}",
        "Alice/OpenAI;Bob/OpenAI;",
      ),
      spec_case(
        "nested dotted names", "{{#project}}{{owner.name}} builds {{name}}{{/project}}",
        "{\"project\":{\"name\":\"moon-mustache\",\"owner\":{\"name\":\"Alice\"}}}",
        "Alice builds moon-mustache",
      ),
      spec_case(
        "current context in list", "{{#items}}<{{.}}>{{/items}}", "{\"items\":[\"scanner\",\"parser\",\"renderer\"]}",
        "<scanner><parser><renderer>",
      ),
      spec_case(
        "parent scope lookup", "{{#items}}{{category}}/{{name}};{{/items}}", "{\"category\":\"core\",\"items\":[{\"name\":\"scanner\"},{\"name\":\"renderer\"}]}",
        "core/scanner;core/renderer;",
      ),
      spec_case(
        "string section renders once", "{{#name}}Hi {{.}}!{{/name}}", "{\"name\":\"MoonBit\"}",
        "Hi MoonBit!",
      ),
      spec_case(
        "empty list section skips body", "A{{#items}}B{{/items}}C", "{\"items\":[]}",
        "AC",
      ),
    ],
  }
}

///|
pub fn inverted_spec_suite() -> SpecSuite {
  {
    name: "inverted",
    cases: [
      spec_case(
        "false boolean renders inverted body", "{{^enabled}}disabled{{/enabled}}",
        "{\"enabled\":false}", "disabled",
      ),
      spec_case(
        "empty list renders inverted body", "{{^items}}empty{{/items}}", "{\"items\":[]}",
        "empty",
      ),
      spec_case(
        "missing value renders inverted body", "{{^missing}}fallback{{/missing}}",
        "{}", "fallback",
      ),
      spec_case(
        "truthy value skips inverted body", "A{{^items}}B{{/items}}C", "{\"items\":[1]}",
        "AC",
      ),
    ],
  }
}

///|
pub fn partial_spec_suite() -> SpecSuite {
  {
    name: "partials",
    cases: [
      spec_case(
        "basic partial",
        "Names: {{#names}}{{> user}}{{/names}}",
        "{\"names\":[{\"name\":\"Alice\"},{\"name\":\"Bob\"}]}",
        "Names: [Alice][Bob]",
        partials_json="{\"user\":\"[{{name}}]\"}",
      ),
      spec_case(
        "partial sees parent scope",
        "{{#items}}{{> row}}{{/items}}",
        "{\"category\":\"core\",\"items\":[{\"name\":\"scanner\"},{\"name\":\"renderer\"}]}",
        "core/scannercore/renderer",
        partials_json="{\"row\":\"{{category}}/{{name}}\"}",
      ),
      spec_case(
        "recursive partial expansion",
        "{{> node}}",
        "{\"content\":\"X\",\"nodes\":[{\"content\":\"Y\",\"nodes\":[]}]}",
        "X<Y<>>",
        partials_json="{\"node\":\"{{content}}<{{#nodes}}{{> node}}{{/nodes}}>\"}",
      ),
      spec_case(
        "missing partial reports diagnostics",
        "A{{> missing}}B",
        "{}",
        "AB",
        expected_errors=["missing partial: missing"],
      ),
      spec_case(
        "malformed partial reports diagnostics",
        "A{{> broken}}B",
        "{}",
        "AB",
        partials_json="{\"broken\":\"{{#user}}Hello\"}",
        expected_errors=["partial broken: unterminated section: user"],
      ),
      spec_case(
        "partial with escaped interpolation",
        "{{> card}}",
        "{\"name\":\"<MoonBit>\"}",
        "&lt;MoonBit&gt;",
        partials_json="{\"card\":\"{{name}}\"}",
      ),
    ],
  }
}

///|
pub fn delimiter_spec_suite() -> SpecSuite {
  {
    name: "delimiters",
    cases: [
      spec_case(
        "basic delimiter change", "{{=<% %>=}}Hello, <%name%>!", "{\"name\":\"MoonBit\"}",
        "Hello, MoonBit!",
      ),
      spec_case(
        "multiple delimiter changes", "{{=<% %>=}}(<%text%>) <%={{ }}=%>{{text}}",
        "{\"text\":\"Hey!\"}", "(Hey!) Hey!",
      ),
      spec_case(
        "section under alternate delimiters", "{{=<% %>=}}<%#items%>(<%.%>)<%/items%>",
        "{\"items\":[\"a\",\"b\"]}", "(a)(b)",
      ),
      spec_case(
        "partial after delimiter reset",
        "{{=<% %>=}}<%={{ }}=%>{{> card}}",
        "{\"name\":\"MoonBit\"}",
        "MoonBit",
        partials_json="{\"card\":\"{{name}}\"}",
      ),
    ],
  }
}

///|
pub fn standalone_spec_suite() -> SpecSuite {
  {
    name: "standalone",
    cases: [
      spec_case(
        "section standalone lines", "| This Is\n{{#boolean}}\n|\n{{/boolean}}\n| A Line\n",
        "{\"boolean\":true}", "| This Is\n|\n| A Line\n",
      ),
      spec_case(
        "inverted standalone lines", "| This Is\n{{^boolean}}\n|\n{{/boolean}}\n| A Line\n",
        "{\"boolean\":false}", "| This Is\n|\n| A Line\n",
      ),
      spec_case(
        "comment standalone lines", "Begin.\n{{! Comment Block! }}\nEnd.\n", "{}",
        "Begin.\nEnd.\n",
      ),
      spec_case(
        "partial standalone lines",
        "Start\n{{> body}}\nFinish\n",
        "{}",
        "Start\nmiddle\nFinish\n",
        partials_json="{\"body\":\"middle\\n\"}",
      ),
      spec_case(
        "delimiter tag standalone line", "|\n{{=<% %>=}}\n| <%name%>\n", "{\"name\":\"MoonBit\"}",
        "|\n| MoonBit\n",
      ),
    ],
  }
}

///|
pub fn whitespace_spec_suite() -> SpecSuite {
  {
    name: "whitespace",
    cases: [
      spec_case(
        "interpolation keeps surrounding spaces", "A {{name}} B", "{\"name\":\"MoonBit\"}",
        "A MoonBit B",
      ),
      spec_case(
        "comment inside text leaves adjacent spaces", "A {{! hidden }} B", "{}",
        "A  B",
      ),
      spec_case(
        "standalone trimming not triggered inline", "A {{#flag}}B{{/flag}} C", "{\"flag\":true}",
        "A B C",
      ),
      spec_case(
        "inline partial stays inline",
        "A{{> word}}B",
        "{}",
        "AcoreB",
        partials_json="{\"word\":\"core\"}",
      ),
      spec_case(
        "delimiter change inline keeps line content", "A {{=<% %>=}}<%name%>", "{\"name\":\"MoonBit\"}",
        "A MoonBit",
      ),
    ],
  }
}

///|
pub fn diagnostics_spec_suite() -> SpecSuite {
  {
    name: "diagnostics",
    cases: [
      spec_case("unterminated section", "{{#user}}Hello", "{}", "", expected_errors=[
        "unterminated section: user",
      ]),
      spec_case(
        "mismatched section ending",
        "{{#user}}Hello{{/team}}",
        "{}",
        "",
        expected_errors=["section end mismatch: expected user, got team"],
      ),
      spec_case(
        "missing partial diagnostic",
        "Start {{> missing}} End",
        "{}",
        "Start  End",
        expected_errors=["missing partial: missing"],
      ),
      spec_case(
        "invalid partial structure diagnostic",
        "{{> broken}}",
        "{}",
        "",
        partials_json="{\"broken\":\"{{#item}}\"}",
        expected_errors=["partial broken: unterminated section: item"],
      ),
    ],
  }
}

///|
pub fn all_spec_suites() -> Array[SpecSuite] {
  [
    interpolation_spec_suite(),
    comment_spec_suite(),
    section_spec_suite(),
    inverted_spec_suite(),
    partial_spec_suite(),
    delimiter_spec_suite(),
    standalone_spec_suite(),
    whitespace_spec_suite(),
    diagnostics_spec_suite(),
  ]
}
