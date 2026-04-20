local geo = require("99.geo")
local CleanUp = require("99.ops.clean-up")

local Point = geo.Point
local Range = geo.Range

local function containing_function(context)
  local data = context:fill_in_function_data()
  local buffer = data.buffer
  local file_type = data.file_type
  local cursor = Point:from_cursor()

  local ok_parser, parser = pcall(vim.treesitter.get_parser, buffer, file_type)
  if not ok_parser or not parser then
    return nil, "missing treesitter parser"
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil, "missing treesitter tree"
  end

  local ok_query, query = pcall(vim.treesitter.query.get, file_type, "99-function")
  if not ok_query or not query then
    return nil, "missing 99-function query"
  end

  local root = tree:root()
  local found_range = nil
  local found_node = nil
  for id, node, _ in query:iter_captures(root, buffer, 0, -1, { all = true }) do
    local name = query.captures[id]
    local range = Range:from_ts_node(node, buffer)
    if name == "context.function" and range:contains(cursor) then
      if not found_range or found_range:area() > range:area() then
        found_range = range
        found_node = node
      end
    end
  end

  if not found_node or not found_range then
    return nil, "cursor is not inside a function"
  end

  local func = {
    function_range = found_range,
    body_range = nil,
  }
  for id, node, _ in query:iter_captures(root, buffer, 0, -1, { all = true }) do
    if query.captures[id] == "context.body" then
      local range = Range:from_ts_node(node, buffer)
      if found_range:contains(range.start) and found_range:contains(range.end_) then
        if not func.body_range or func.body_range:area() > range:area() then
          func.body_range = range
        end
      end
    end
  end

  if not func.body_range then
    local row = func.function_range.end_.row
    func.body_range = Range:new(
      buffer,
      Point:from_1_based(row, 1),
      Point:from_1_based(row, 1)
    )
  end

  return func
end

return function(context, opts)
  opts = opts or {}
  local logger = context.logger:set_area("fill_in_function")
  local func, err = containing_function(context)
  if not func then
    logger:error("fill_in_function unavailable", "reason", err)
    return
  end

  local data = context:fill_in_function_data()
  data.range = func.function_range
  local prompt = table.concat({
    "Implement the function body for the function below.",
    "Return only the function body contents.",
    "Do not include markdown fences or explanations.",
    "<FUNCTION>",
    func.function_range:to_text(),
    "</FUNCTION>",
  }, "\n")

  if opts.additional_prompt then
    context.user_prompt = opts.additional_prompt
    prompt = context._99.prompts.prompts.prompt(opts.additional_prompt, prompt)
  end

  context:add_prompt_content(prompt)
  context:start_request(CleanUp.make_observer(context, function(status, response)
    if status ~= "success" then
      return
    end
    if vim.trim(response) == "" then
      return
    end
    local lines = vim.split(response, "\n")
    if func.body_range.start:eq(func.body_range.end_) then
      local existing = func.body_range.start:line(data.buffer)
      if existing and existing ~= "" then
        table.insert(lines, "")
      end
    end
    func.body_range:replace_text(lines)
  end))
end
