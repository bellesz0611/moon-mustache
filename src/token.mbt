pub enum TokenKind {
  Text
  Variable
  UnescapedVariable
  SectionStart
  SectionEnd
  InvertedSectionStart
  Partial
  Comment
  SetDelimiter
}

pub struct Token {
  kind : TokenKind
  lexeme : String
  start : Int
  end_ : Int
}

pub fn Token::new(kind : TokenKind, lexeme : String, start : Int, end_ : Int) -> Token {
  { kind, lexeme, start, end_ }
}

pub fn Token::is_tag(self : Token) -> Bool {
  match self.kind {
    Text => false
    _ => true
  }
}

