; Block & declaration bodies
[
  (block)
  (declaration_list)
  (accessor_list)
  (enum_member_declaration_list)
  (switch_body)
  (initializer_expression)
] @indent.begin

; Closing delimiters
[
  ")"
  "}"
  "]"
] @indent.branch

(block
  "}" @indent.end)

(declaration_list
  "}" @indent.end)

(accessor_list
  "}" @indent.end)

(enum_member_declaration_list
  "}" @indent.end)

(switch_body
  "}" @indent.end)

; Alignment for argument/parameter lists
([
  (argument_list)
  (parameter_list)
] @indent.align
  (#set! indent.open_delimiter "(")
  (#set! indent.close_delimiter ")"))

; Ignore strings
[
  (string_literal)
  (verbatim_string_literal)
  (interpolated_string_expression)
] @indent.ignore

(comment) @indent.auto
