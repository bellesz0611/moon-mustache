pub enum Value {
  Null
  Bool(Bool)
  Number(Double)
  String(String)
  Object(Map[String, Value])
  Array(Array[Value])
}

pub fn lookup_name(root : Value, name : String) -> Value? {
  match root {
    Object(map) => map.get(name)
    _ => None
  }
}

pub fn value_to_string(value : Value) -> String {
  match value {
    Null => ""
    Bool(v) => if v { "true" } else { "false" }
    Number(v) => v.to_string()
    String(v) => v
    Object(_) => "[object]"
    Array(_) => "[array]"
  }
}

