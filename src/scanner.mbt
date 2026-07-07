///|
pub struct ScanState {
  open_delim : String
  close_delim : String
}

///|
pub fn default_scan_state() -> ScanState {
  { open_delim: "{{", close_delim: "}}" }
}

///|
pub fn scan_template(input : String) -> Array[Token] {
  let state = default_scan_state()
  scan_with_state(input, state)
}

///|
fn push_text_token(
  tokens : Array[Token],
  input : String,
  start : Int,
  end_ : Int,
) -> Unit {
  if end_ > start {
    let text = input[:].view(start_offset=start, end_offset=end_).to_owned()
    tokens.push(Token::new(Text, text, start, end_))
  }
}

///|
fn slice_owned(input : String, start : Int, end_ : Int) -> String {
  input[:].view(start_offset=start, end_offset=end_).to_owned()
}

///|
fn is_standalone_candidate(kind : TokenKind) -> Bool {
  match kind {
    SectionStart
    | SectionEnd
    | InvertedSectionStart
    | Partial
    | Comment
    | SetDelimiter => true
    _ => false
  }
}

///|
fn is_standalone_whitespace(input : String, start : Int, end_ : Int) -> Bool {
  let mut index = start
  while index < end_ {
    let ch = input.unsafe_get(index)
    if ch != ' ' && ch != '\t' && ch != '\r' {
      return false
    }
    index = index + 1
  }
  true
}

///|
fn line_start_index(input : String, index : Int) -> Int {
  let mut cursor = index
  while cursor > 0 {
    let previous = input.unsafe_get(cursor - 1)
    if previous == '\n' || previous == '\r' {
      break
    }
    cursor = cursor - 1
  }
  cursor
}

///|
fn standalone_line_end(input : String, start : Int) -> Int? {
  let mut cursor = start
  while cursor < input.length() {
    let ch = input.unsafe_get(cursor)
    if ch == ' ' || ch == '\t' {
      cursor = cursor + 1
      continue
    }
    if ch == '\r' {
      if cursor + 1 < input.length() && input.unsafe_get(cursor + 1) == '\n' {
        return Some(cursor + 2)
      }
      return Some(cursor + 1)
    }
    if ch == '\n' {
      return Some(cursor + 1)
    }
    return None
  }
  Some(cursor)
}

///|
fn parse_set_delimiters(spec : String, state : ScanState) -> ScanState {
  match spec.split_once(" ") {
    Some((open, close)) => {
      let next_open = open.trim().to_owned()
      let next_close = close.trim().to_owned()
      if next_open.length() > 0 && next_close.length() > 0 {
        { open_delim: next_open, close_delim: next_close }
      } else {
        state
      }
    }
    None => state
  }
}

///|
fn classify_tag(
  content : String,
  start : Int,
  end_ : Int,
  state : ScanState,
) -> (Token, ScanState) {
  let trimmed = content.trim()
  if trimmed.length() == 0 {
    return (Token::new(Variable, "", start, end_), state)
  }
  let first = trimmed.unsafe_get(0)
  match first {
    '#' =>
      (
        Token::new(
          SectionStart,
          trimmed.view(start_offset=1).trim().to_owned(),
          start,
          end_,
        ),
        state,
      )
    '^' =>
      (
        Token::new(
          InvertedSectionStart,
          trimmed.view(start_offset=1).trim().to_owned(),
          start,
          end_,
        ),
        state,
      )
    '/' =>
      (
        Token::new(
          SectionEnd,
          trimmed.view(start_offset=1).trim().to_owned(),
          start,
          end_,
        ),
        state,
      )
    '!' =>
      (
        Token::new(
          Comment,
          trimmed.view(start_offset=1).trim().to_owned(),
          start,
          end_,
        ),
        state,
      )
    '>' =>
      (
        Token::new(
          Partial,
          trimmed.view(start_offset=1).trim().to_owned(),
          start,
          end_,
        ),
        state,
      )
    '&' =>
      (
        Token::new(
          UnescapedVariable,
          trimmed.view(start_offset=1).trim().to_owned(),
          start,
          end_,
        ),
        state,
      )
    _ =>
      match trimmed.strip_prefix("=") {
        Some(rest) =>
          match rest.to_owned().strip_suffix("=") {
            Some(inner) => {
              let spec = inner.to_owned().trim().to_owned()
              let next_state = parse_set_delimiters(spec, state)
              (Token::new(SetDelimiter, spec, start, end_), next_state)
            }
            None =>
              (Token::new(Variable, trimmed.to_owned(), start, end_), state)
          }
        None => (Token::new(Variable, trimmed.to_owned(), start, end_), state)
      }
  }
}

///|
pub fn scan_with_state(input : String, state : ScanState) -> Array[Token] {
  let tokens : Array[Token] = []
  let mut cursor = 0
  let mut current_state = state

  while cursor < input.length() {
    let open_delim = current_state.open_delim
    let close_delim = current_state.close_delim
    let remaining = input[:].view(start_offset=cursor)
    match remaining.find(open_delim) {
      None => {
        push_text_token(tokens, input, cursor, input.length())
        break
      }
      Some(rel_open) => {
        let open_index = cursor + rel_open

        let is_triple_brace = open_delim == "{{" &&
          open_index + 3 <= input.length() &&
          input[:].view(start_offset=open_index, end_offset=open_index + 3) ==
          "{{{"

        if is_triple_brace {
          push_text_token(tokens, input, cursor, open_index)
          let triple_start = open_index + 3
          match input[:].view(start_offset=triple_start).find("}}}") {
            None => {
              push_text_token(tokens, input, open_index, input.length())
              break
            }
            Some(rel_close) => {
              let close_index = triple_start + rel_close
              let name = input[:]
                .view(start_offset=triple_start, end_offset=close_index)
                .trim()
                .to_owned()
              tokens.push(
                Token::new(UnescapedVariable, name, open_index, close_index + 3),
              )
              cursor = close_index + 3
              continue
            }
          }
        }

        let tag_start = open_index + open_delim.length()
        match input[:].view(start_offset=tag_start).find(close_delim) {
          None => {
            push_text_token(tokens, input, open_index, input.length())
            break
          }
          Some(rel_close) => {
            let close_index = tag_start + rel_close
            let raw_content = input[:]
              .view(start_offset=tag_start, end_offset=close_index)
              .to_owned()
            let (token, next_state) = classify_tag(
              raw_content,
              open_index,
              close_index + close_delim.length(),
              current_state,
            )
            let tag_end = close_index + close_delim.length()
            let line_start = line_start_index(input, open_index)
            let can_be_standalone = is_standalone_candidate(token.kind) &&
              is_standalone_whitespace(input, line_start, open_index)
            let standalone_end = if can_be_standalone {
              standalone_line_end(input, tag_end)
            } else {
              None
            }
            let text_end = match standalone_end {
              Some(_) => line_start
              None => open_index
            }
            push_text_token(tokens, input, cursor, text_end)
            let final_token = match (token.kind, standalone_end) {
              (Partial, Some(_)) =>
                Token::with_indentation(
                  token.kind,
                  token.lexeme,
                  token.start,
                  token.end_,
                  Some(slice_owned(input, line_start, open_index)),
                )
              _ => token
            }
            tokens.push(final_token)
            current_state = next_state
            cursor = match standalone_end {
              Some(next_cursor) => next_cursor
              None => tag_end
            }
          }
        }
      }
    }
  }
  tokens
}
