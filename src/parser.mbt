pub struct ParseResult {
  nodes : Array[Node]
  errors : Array[String]
}

pub fn parse_template(input : String) -> ParseResult {
  let tokens = scan_template(input)
  parse_tokens(tokens)
}

pub fn parse_tokens(tokens : Array[Token]) -> ParseResult {
  let nodes : Array[Node] = []
  let errors : Array[String] = []

  for token in tokens {
    match token.kind {
      Text => nodes.push(Node::text(token.lexeme))
      Variable => nodes.push(Node::variable(token.lexeme))
      UnescapedVariable => nodes.push(Node::raw_variable(token.lexeme))
      Comment => nodes.push(Comment(token.lexeme))
      _ => errors.push("parser branch not implemented: " + token.lexeme)
    }
  }

  { nodes, errors }
}
