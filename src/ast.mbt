pub enum Node {
  Text(String)
  Variable(name~ : String, escaped~ : Bool)
  Section(name~ : String, inverted~ : Bool, children~ : Array[Node])
  Partial(name~ : String)
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
