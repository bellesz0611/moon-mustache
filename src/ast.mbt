///|
pub enum Node {
  Text(String)
  Variable(name~ : String, escaped~ : Bool)
  Section(name~ : String, inverted~ : Bool, children~ : Array[Node])
  Partial(name~ : String, indentation~ : String?)
  Comment(String)
}

///|
pub fn Node::text(content : String) -> Node {
  Text(content)
}

///|
pub fn Node::variable(name : String) -> Node {
  Variable(name~, escaped=true)
}

///|
pub fn Node::raw_variable(name : String) -> Node {
  Variable(name~, escaped=false)
}

///|
pub fn Node::section(name : String, children : Array[Node]) -> Node {
  Section(name~, inverted=false, children~)
}

///|
pub fn Node::inverted_section(name : String, children : Array[Node]) -> Node {
  Section(name~, inverted=true, children~)
}

///|
pub fn Node::partial(name : String, indentation? : String? = None) -> Node {
  Partial(name~, indentation~)
}

///|
pub fn Node::comment(content : String) -> Node {
  Comment(content)
}
