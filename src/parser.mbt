pub struct ParseResult {
  nodes : Array[Node]
  errors : Array[String]
}

pub fn parse_template(input : String) -> ParseResult {
  let tokens = scan_template(input)
  parse_tokens(tokens)
}

fn parse_nodes(
  tokens : Array[Token],
  start : Int,
  expected_end : String?,
) -> (Array[Node], Int, Array[String]) {
  let nodes : Array[Node] = []
  let errors : Array[String] = []
  let mut index = start

  while index < tokens.length() {
    let token = tokens[index]
    match token.kind {
      Text => {
        nodes.push(Node::text(token.lexeme))
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
      SectionStart => {
        let (children, next_index, child_errors) = parse_nodes(
          tokens,
          index + 1,
          Some(token.lexeme),
        )
        for error in child_errors {
          errors.push(error)
        }
        nodes.push(Node::section(token.lexeme, children))
        index = next_index
      }
      InvertedSectionStart => {
        let (children, next_index, child_errors) = parse_nodes(
          tokens,
          index + 1,
          Some(token.lexeme),
        )
        for error in child_errors {
          errors.push(error)
        }
        nodes.push(Node::inverted_section(token.lexeme, children))
        index = next_index
      }
      SectionEnd =>
        match expected_end {
          Some(name) => {
            if token.lexeme != name {
              errors.push(
                "section end mismatch: expected " + name + ", got " + token.lexeme,
              )
            }
            return (nodes, index + 1, errors)
          }
          None => {
            errors.push("unexpected section end: " + token.lexeme)
            index = index + 1
          }
        }
      SetDelimiter => {
        index = index + 1
      }
    }
  }

  match expected_end {
    Some(name) => errors.push("unterminated section: " + name)
    None => ()
  }

  (nodes, index, errors)
}

pub fn parse_tokens(tokens : Array[Token]) -> ParseResult {
  let (nodes, _, errors) = parse_nodes(tokens, 0, None)
  { nodes, errors }
}
