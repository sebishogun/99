(function_definition) @context.function
(lambda) @context.function

(function_definition
  body: (block) @context.body)

; class methods
(class_definition
  body: (block
    (function_definition) @context.function))

; async functions
(function_definition
  (async) @context.async) @context.function
