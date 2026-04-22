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

  it("includes additional prompt text in the provider query", function()
    local content = {
      "local foo = function()",
      "end",
    }
    local provider = test_utils.test_setup(content, 1, 18, "lua")

    _99.fill_in_function({
      additional_prompt = "Use the existing naming style and keep it concise.",
    })

    local request = assert(provider.request)
    assert.is_truthy(
      request.query:find("Use the existing naming style", 1, true)
    )
    assert.is_truthy(request.query:find("Implement the function body", 1, true))
  end)

  it("fills in a typescript function body", function()
    local content = {
      "const foo = function() {}",
    }
    local provider, buffer = test_utils.test_setup(content, 1, 22, "typescript")

    _99.fill_in_function()

    provider:resolve("success", "  return 42;")
    test_utils.next_frame()

    eq({
      "const foo = function() {",
      "  return 42;",
      "}",
    }, test_utils.r(buffer))
  end)

  it("does not start a request when cursor is outside a function", function()
    local content = {
      "local foo = 42",
    }
    local provider = test_utils.test_setup(content, 1, 1, "lua")
    local state = _99.__get_state()

    _99.fill_in_function()

    eq(0, state.tracking:active_count())
    eq(nil, provider.request)
  end)
end)
