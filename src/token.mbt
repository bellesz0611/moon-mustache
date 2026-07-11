///|
pub enum TokenKind {
  Text
  Variable
  UnescapedVariable
  SectionStart
  SectionEnd
  InvertedSectionStart
  Partial
  DynamicPartial
  ParentStart
  BlockStart
  Comment
  SetDelimiter
}

///|
pub struct Token {
  kind : TokenKind
  lexeme : String
  start : Int
  end_ : Int
  indentation : String?
  standalone : Bool
  paired : Bool
  open_delim : String
  close_delim : String
}

///|
pub fn Token::new(
  kind : TokenKind,
  lexeme : String,
  start : Int,
  end_ : Int,
) -> Token {
  {
    kind,
    lexeme,
    start,
    end_,
    indentation: None,
    standalone: false,
    paired: false,
    open_delim: "{{",
    close_delim: "}}",
  }
}

///|
pub fn Token::with_indentation(
  kind : TokenKind,
  lexeme : String,
  start : Int,
  end_ : Int,
  indentation : String?,
  standalone? : Bool = true,
  paired? : Bool = false,
) -> Token {
  {
    kind,
    lexeme,
    start,
    end_,
    indentation,
    standalone,
    paired,
    open_delim: "{{",
    close_delim: "}}",
  }
}

///|
pub fn Token::with_delimiters(
  self : Token,
  open_delim : String,
  close_delim : String,
) -> Token {
  {
    kind: self.kind,
    lexeme: self.lexeme,
    start: self.start,
    end_: self.end_,
    indentation: self.indentation,
    standalone: self.standalone,
    paired: self.paired,
    open_delim,
    close_delim,
  }
}

///|
pub fn Token::is_tag(self : Token) -> Bool {
  match self.kind {
    Text => false
    _ => true
  }
}
