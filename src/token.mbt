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
  indentation : String?
}

pub fn Token::new(kind : TokenKind, lexeme : String, start : Int, end_ : Int) -> Token {
  { kind, lexeme, start, end_, indentation: None }
}

pub fn Token::with_indentation(
  kind : TokenKind,
  lexeme : String,
  start : Int,
  end_ : Int,
  indentation : String?,
) -> Token {
  { kind, lexeme, start, end_, indentation }
}

pub fn Token::is_tag(self : Token) -> Bool {
  match self.kind {
    Text => false
    _ => true
  }
}
