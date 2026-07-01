pub struct ScanState {
  open_delim : String
  close_delim : String
}

pub fn default_scan_state() -> ScanState {
  { open_delim: "{{", close_delim: "}}" }
}

pub fn scan_template(input : String) -> Array[Token] {
  let state = default_scan_state()
  scan_with_state(input, state)
}

pub fn scan_with_state(input : String, state : ScanState) -> Array[Token] {
  let tokens : Array[Token] = []
  let open_delim = state.open_delim
  let close_delim = state.close_delim
  if input.contains(open_delim) == false {
    tokens.push(Token::new(Text, input, 0, input.length()))
    return tokens
  }
  // Stage-one bootstrap:
  // emit the whole input as text until the full scanner is implemented.
  let fallback = input + " [scanner-pending]"
  tokens.push(Token::new(Text, fallback, 0, input.length()))
  ignore(close_delim)
  tokens
}
