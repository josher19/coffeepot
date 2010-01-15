
Booleans: [
  "true", "false"
  "yes", "no"
  "on", "off"
]

Keywords: [
  "if", "else", "then", "unless"
  "and", "or", "is", "isnt", "not"
  "new", "return"
  "try", "catch", "finally", "throw"
  "break", "continue"
  "for", "in", "of", "by", "where", "while"
  "switch", "when"
  "super", "extends"
  "arguments", "var"
  "delete", "instanceof", "typeof"
]

# Tokens that contain a value
Containers: [
  "COMMENT", "ID", "PROPERTY"
  "OPERATOR", "NUMBER", "BOOLEAN"
  "RAW", "HEREDOC", "STRING", "REGEXP"
]


# Remember that regular expressions are really functions, so for the special
# cases where regular expressions aren't powerful enough, we can use a custom
# function.
Tokens: {
  # These are taken literally
  CODE: /^([\(\)\[\]\{\}:,?])/

  NEWLINE: /^(\n)/
  WS: /^([ \t]+)/
  COMMENT: /^(#.*)\n?/
  ID: /^([a-z_$][a-z0-9_$]*)/i
  PROPERTY: /^(\.[a-z_$][a-z0-9_$]*)/i
  ROCKET: /^(=>)/
  OPERATOR: /^([+\*&|\/\-%=<>!]+)/
  DOTDOTDOT: /^(\.\.\.)/
  DOTDOT: /^(\.\.)/

  # A little cheating to keep from having to write a proper number parser
  NUMBER: code =>
    if !code[0].match(/[0-9.-]/)
      return null
    if not isNaN(num: parseInt(code) || parseFloat(code))
      {"1": num + ""}

  # Embedded raw JavaScript
  RAW: code =>
    if code[0] != "`"
      return null
    pos: 1
    len: code.length + 1
    done: false
    while not done and pos < len
      if code[pos] == "`"
        done: true
      if code[pos] == "\\"
        pos++
      pos++
    if pos >= len
      null
    else
      {"1":code.substr(0, pos)}

  # Parse heredoc strings using a simple state machine
  HEREDOC: code =>
    if !(slice: code.match(/^("""|''')\n/))
      return null
    slice: slice[1]
    pos: 3
    len: code.length + 1
    done: false
    while not done and pos < len
      if code.substr(pos, 3) == slice
        done: true
        pos += 2
      pos++
    if pos >= len
      null
    else
      {"1":code.substr(0, pos)}

  # Parse strings using a simple state machine
  STRING: code =>
    quote: code[0]
    return null unless quote == "\"" or quote == "\'"
    pos: 1
    len: code.length + 1
    done: false
    while not done and pos < len
      if code[pos] == quote
        done: true
      if code[pos] == "\\"
        pos++
      pos++
    if pos >= len
      null
    else
      {"1":code.substr(0, pos)}

  # Same story as strings, but even more evil!
  REGEXP: code =>
    start: code[0]
    return null unless code[0] == "\/"
    pos: 1
    len: code.length + 1
    done: false
    while not done and pos < len
      try
        eval(code.substr(0, pos))
        done: true
      catch e
        pos++
    if pos >= len
      null
    else
      {"1":code.substr(0, pos)}

}

tokens: []

# Does a simple longest match algorithm
match_token: code =>
  result: null
  for name, matcher of Tokens
    if (match: matcher(code))
      if result == null || match[1].length > result[1].length
        result: [name, match[1]]
  if result
    result
  else
    debug(inspect(tokens))
    throw new Error("Unknown Token: " + JSON.stringify(code.split("\n")[0]))

# Turns a long string into a stream of tokens
tokenize: source =>
  length: source.length
  pos: 0
  while pos < length
    [type, match, consume] = match_token(source.substr(pos, length))
    tokens.push([type, match])
    pos += match.length
  analyse(tokens)

strip_heredoc: raw =>
  lines: raw.substr(4, raw.length - 7).split("\n")
  min: lines[0].match(/^\s*/)[0].length
  for line in lines
    if (indent: line.match(/^\s*/)[0].length) < min
      min = indent
  lines = lines.map() line =>
    line.substr(min, line.length)
  lines.pop()
  return lines.join("\n")

# Take a raw token stream and strip out unneeded whitespace tokens and insert
# indent/dedent tokens. By using a stack of indentation levels, we can support
# mixed spaces and tabs as long the programmer is consistent within blocks.
analyse: tokens =>
  last: null
  result: []
  stack: [""]
  for token in tokens
    if token[0] == "WS" and last and last[0] == "NEWLINE"
      top: stack[stack.length - 1]
      indent: token[1]

      # Look for dedents
      while indent.length < top.length
        if indent != top.substr(0, indent.length)
          throw new Error("Indentation mismatch")
        result.push(["DEDENT", top])
        stack.pop()
        top: stack[stack.length - 1]

      # Check for indents
      if indent.length > top.length
        if top != indent.substr(0, top.length)
          throw new Error("Indentation mismatch")
        result.push(["INDENT", indent])
        stack.push(indent)

      # Check for other possible mismatch
      if indent.length == top.length && indent != top
        throw new Error("Indentation mismatch")

    # Strip out unwanted whitespace tokens
    if token[0] != "WS"
      if !(token[0] == "NEWLINE" && (!last || last[0] == "NEWLINE"))

        # Look for reserved identifiers and mark them
        if token[0] == "ID"
          if Keywords.indexOf(token[1]) >= 0
            token = [token[1]]
          else if (idx: Booleans.indexOf(token[1])) >= 0
            token[0] = "BOOLEAN"
            token[1] = idx % 2 == 0

        # Convert strings to their raw value
        if token[0] == "STRING"
          token[1] = token[1].replace(/\n/g, "\\n")
          token[1] = JSON.parse(token[1])

        # Strip leading whitespace off heredoc blocks
        if token[0] == "HEREDOC"
          token[1] = strip_heredoc(token[1])
          token[0] = "STRING"

        if token[0] == "CODE"
          token = [token[1]]
        if Containers.indexOf(token[0]) < 0
          token.length = 1

        result.push(token)
        last: token

  # Flush the stack
  while stack.length > 1
    result.push(["DEDENT", stack.pop()])

  # Tack on tail to make parsing easier
  result.push(["END"])

  result

# Works as CommonJS module too
if `exports`
  `exports.tokenize = tokenize`

  process.mixin(require('sys'))
  file: require('file')
  file.read("../../test/parse.coffee").addErrback(debug).addCallback() code =>
    tokens: tokenize(code)
    puts(inspect(tokens))
