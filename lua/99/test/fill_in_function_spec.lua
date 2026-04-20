-- luacheck: globals describe it assert
local _99 = require("99")
local eq = assert.are.same
local test_utils = require("99.test.test_utils")

describe("fill_in_function", function()
  it("replaces the current function body from provider output", function()
    local content = {
      "local foo = function()",
      "end",
    }
    local provider, buffer = test_utils.test_setup(content, 1, 18, "lua")
    local state = _99.__get_state()

    _99.fill_in_function()

    eq(1, state.tracking:active_count())
    eq(content, test_utils.r(buffer))

    provider:resolve("success", "  return 42")
    test_utils.next_frame()

    eq({
      "local foo = function()",
      "  return 42",
      "end",
    }, test_utils.r(buffer))
    eq(0, state.tracking:active_count())
  end)

  it("exposes fill_in_function_prompt", function()
    eq("function", type(_99.fill_in_function_prompt))
  end)
end)
