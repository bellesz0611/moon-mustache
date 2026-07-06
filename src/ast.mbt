pub enum Node {
  Text(String)
  Variable(name~ : String, escaped~ : Bool)
  Section(name~ : String, inverted~ : Bool, children~ : Array[Node])
  Partial(name~ : String, indentation~ : String?)
  Comment(String)
}

pub fn Node::text(content : String) -> Node {
  Text(content)
}

pub fn Node::variable(name : String) -> Node {
  Variable(name=name, escaped=true)
}

pub fn Node::raw_variable(name : String) -> Node {
  Variable(name=name, escaped=false)
}

pub fn Node::section(name : String, children : Array[Node]) -> Node {
  Section(name=name, inverted=false, children=children)
}

pub fn Node::inverted_section(name : String, children : Array[Node]) -> Node {
  Section(name=name, inverted=true, children=children)
}

pub fn Node::partial(name : String, indentation? : String? = None) -> Node {
  Partial(name=name, indentation=indentation)
}

pub fn Node::comment(content : String) -> Node {
  Comment(content)
}
