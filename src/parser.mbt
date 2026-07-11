///|
pub struct ParseResult {
  nodes : Array[Node]
  errors : Array[String]
  diagnostics : Array[Diagnostic]
}

///|
pub fn parse_template(input : String) -> ParseResult {
  let tokens = scan_template(input)
  parse_tokens_with_source(tokens, input)
}

///|
fn tag_is_followed_by_line_end(source : String, end_ : Int) -> Bool {
  let mut cursor = end_
  while cursor < source.length() {
    let char = source.unsafe_get(cursor)
    if char == ' ' || char == '\t' {
      cursor = cursor + 1
      continue
    }
    return char == '\n' || char == '\r'
  }
  true
}

///|
fn section_raw_source(source : String, start : Int, end_ : Int) -> String {
  if start < 0 || end_ < start || start > source.length() {
    return ""
  }
  let safe_end = if end_ > source.length() { source.length() } else { end_ }
  source[:].view(start_offset=start, end_offset=safe_end).to_owned()
}

///|
fn parse_nodes(
  tokens : Array[Token],
  start : Int,
  expected_end : String?,
  source : String,
) -> (Array[Node], Int, Array[Diagnostic]) {
  let nodes : Array[Node] = []
  let diagnostics : Array[Diagnostic] = []
  let mut index = start
  let mut suppress_next_newline = false

  while index < tokens.length() {
    let token = tokens[index]
    match token.kind {
      Text => {
        let text = if suppress_next_newline && token.lexeme.has_prefix("\r\n") {
          token.lexeme[:].view(start_offset=2).to_owned()
        } else if suppress_next_newline && token.lexeme.has_prefix("\n") {
          token.lexeme[:].view(start_offset=1).to_owned()
        } else {
          token.lexeme
        }
        nodes.push(Node::text(text))
        suppress_next_newline = false
        index = index + 1
      }
      Variable => {
        nodes.push(Node::variable(token.lexeme))
        index = index + 1
      }
      UnescapedVariable => {
        nodes.push(Node::raw_variable(token.lexeme))
        index = index + 1
      }
      Comment => {
        nodes.push(Node::comment(token.lexeme))
        index = index + 1
      }
      Partial => {
        nodes.push(Node::partial(token.lexeme, indentation=token.indentation))
        index = index + 1
      }
      DynamicPartial => {
        nodes.push(
          Node::dynamic_partial(token.lexeme, indentation=token.indentation),
        )
        index = index + 1
      }
      ParentStart => {
        let (children, next_index, child_errors) = parse_nodes(
          tokens,
          index + 1,
          Some(token.lexeme),
          source,
        )
        for error in child_errors {
          diagnostics.push(error)
        }
        nodes.push(
          Node::parent(
            token.lexeme,
            children,
            indentation=token.indentation,
            standalone=token.standalone,
          ),
        )
        let closing_token = tokens[next_index - 1]
        let parent_occupies_line = token.indentation is Some(_) &&
          tag_is_followed_by_line_end(source, closing_token.end_)
        if token.paired || (parent_occupies_line && !closing_token.standalone) {
          suppress_next_newline = true
        }
        index = next_index
      }
      BlockStart => {
        let (children, next_index, child_errors) = parse_nodes(
          tokens,
          index + 1,
          Some(token.lexeme),
          source,
        )
        for error in child_errors {
          diagnostics.push(error)
        }
        nodes.push(
          Node::block(
            token.lexeme,
            children,
            indentation=token.indentation,
            standalone=token.standalone,
          ),
        )
        index = next_index
      }
      SectionStart => {
        let (children, next_index, child_errors) = parse_nodes(
          tokens,
          index + 1,
          Some(token.lexeme),
          source,
        )
        for error in child_errors {
          diagnostics.push(error)
        }
        let closing_token = tokens[next_index - 1]
        nodes.push(
          Node::section(
            token.lexeme,
            children,
            raw=section_raw_source(source, token.end_, closing_token.start),
            open_delim=token.open_delim,
            close_delim=token.close_delim,
          ),
        )
        index = next_index
      }
      InvertedSectionStart => {
        let (children, next_index, child_errors) = parse_nodes(
          tokens,
          index + 1,
          Some(token.lexeme),
          source,
        )
        for error in child_errors {
          diagnostics.push(error)
        }
        let closing_token = tokens[next_index - 1]
        nodes.push(
          Node::inverted_section(
            token.lexeme,
            children,
            raw=section_raw_source(source, token.end_, closing_token.start),
            open_delim=token.open_delim,
            close_delim=token.close_delim,
          ),
        )
        index = next_index
      }
      SectionEnd =>
        match expected_end {
          Some(name) => {
            if token.lexeme != name {
              diagnostics.push(
                make_diagnostic(
                  source,
                  "MST-PARSE-002",
                  DiagnosticError,
                  "section end mismatch: expected " +
                  name +
                  ", got " +
                  token.lexeme,
                  token.start,
                  token.end_,
                ),
              )
            }
            return (nodes, index + 1, diagnostics)
          }
          None => {
            diagnostics.push(
              make_diagnostic(
                source,
                "MST-PARSE-001",
                DiagnosticError,
                "unexpected section end: " + token.lexeme,
                token.start,
                token.end_,
              ),
            )
            index = index + 1
          }
        }
      SetDelimiter => index = index + 1
    }
  }

  match expected_end {
    Some(name) =>
      diagnostics.push(
        make_diagnostic(
          source,
          "MST-PARSE-003",
          DiagnosticError,
          "unterminated section: " + name,
          source.length(),
          source.length(),
        ),
      )
    None => ()
  }

  (nodes, index, diagnostics)
}

///|
fn parse_tokens_with_source(
  tokens : Array[Token],
  source : String,
) -> ParseResult {
  let (nodes, _, diagnostics) = parse_nodes(tokens, 0, None, source)
  let errors = diagnostics.map(diagnostic => diagnostic.message)
  { nodes, errors, diagnostics }
}

///|
pub fn parse_tokens(tokens : Array[Token]) -> ParseResult {
  parse_tokens_with_source(tokens, "")
}
