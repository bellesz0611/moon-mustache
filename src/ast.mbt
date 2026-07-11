///|
pub enum Node {
  Text(String)
  Variable(name~ : String, escaped~ : Bool)
  Section(
    name~ : String,
    inverted~ : Bool,
    children~ : Array[Node],
    raw~ : String,
    open_delim~ : String,
    close_delim~ : String
  )
  Partial(name~ : String, indentation~ : String?)
  DynamicPartial(name~ : String, indentation~ : String?)
  Parent(
    name~ : String,
    children~ : Array[Node],
    indentation~ : String?,
    standalone~ : Bool
  )
  Block(
    name~ : String,
    children~ : Array[Node],
    indentation~ : String?,
    standalone~ : Bool
  )
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
pub fn Node::section(
  name : String,
  children : Array[Node],
  raw? : String = "",
  open_delim? : String = "{{",
  close_delim? : String = "}}",
) -> Node {
  Section(name~, inverted=false, children~, raw~, open_delim~, close_delim~)
}

///|
pub fn Node::inverted_section(
  name : String,
  children : Array[Node],
  raw? : String = "",
  open_delim? : String = "{{",
  close_delim? : String = "}}",
) -> Node {
  Section(name~, inverted=true, children~, raw~, open_delim~, close_delim~)
}

///|
pub fn Node::partial(name : String, indentation? : String? = None) -> Node {
  Partial(name~, indentation~)
}

///|
pub fn Node::dynamic_partial(
  name : String,
  indentation? : String? = None,
) -> Node {
  DynamicPartial(name~, indentation~)
}

///|
pub fn Node::parent(
  name : String,
  children : Array[Node],
  indentation? : String? = None,
  standalone? : Bool = false,
) -> Node {
  Parent(name~, children~, indentation~, standalone~)
}

///|
pub fn Node::block(
  name : String,
  children : Array[Node],
  indentation? : String? = None,
  standalone? : Bool = false,
) -> Node {
  Block(name~, children~, indentation~, standalone~)
}

///|
pub fn Node::comment(content : String) -> Node {
  Comment(content)
}
