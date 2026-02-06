(function_item) @context.function
(closure_expression) @context.function

(function_item
  body: (block) @context.body)

(closure_expression
  body: (block) @context.body)

; impl methods
(impl_item
  body: (declaration_list
    (function_item) @context.function))
