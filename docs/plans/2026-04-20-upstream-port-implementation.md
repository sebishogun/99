# Upstream Port Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Port the fork onto current upstream `99`, re-add fork-specific providers and diagnostics, and rebuild `fill_in_function` on upstream's prompt architecture.

**Architecture:** Start from upstream `master`, keep upstream request/state/tracking unchanged, and add fork features as upstream-native modules and API methods. Implement `fill_in_function` via a new op that uses `Prompt` and treesitter-derived function context instead of the removed legacy request context.

**Tech Stack:** Lua, Neovim API, treesitter queries, plenary busted tests, git worktrees

---

### Task 1: Baseline And Branch Hygiene

**Files:**
- Modify: `.gitignore`
- Verify: `Makefile`, `AGENTS.md`

**Step 1: Verify the worktree baseline**

Run: `make pr_ready`
Expected: Either baseline passes, or missing local tools/failures are recorded before implementation begins.

**Step 2: Record any missing host dependencies**

Run: `command -v luacheck stylua nvim`
Expected: Know exactly which local tools block full verification.

**Step 3: Commit setup-only changes**

Run:
```bash
git add .gitignore docs/plans/2026-04-20-upstream-port-design.md docs/plans/2026-04-20-upstream-port-implementation.md
git commit -m "docs: add upstream port design and plan"
```

**Step 4: Push the branch**

Run: `git push -u origin upstream-port`
Expected: Remote branch exists for iterative work.

### Task 2: Port Provider And Runtime Additions

**Files:**
- Modify: `lua/99/providers.lua`
- Modify: `lua/99/init.lua`
- Test: `lua/99/test/providers_spec.lua`
- Test: `lua/99/test/*` as needed for public API coverage

**Step 1: Write failing provider tests**

Add tests for:
- `CopilotCLIProvider` command construction
- `CodexProvider` command construction
- chosen default model values
- any renamed Gemini/OpenCode behavior that must remain from the fork

**Step 2: Run the focused tests to verify they fail**

Run: `make lua_test`
Expected: Failures mention missing providers or wrong command/model expectations.

**Step 3: Implement minimal provider additions**

Add the providers to `lua/99/providers.lua` using upstream `BaseProvider` conventions and expose them from the returned table.

**Step 4: Add runtime API coverage**

Expose or restore small public helpers in `lua/99/init.lua` if tests require them, especially `doctor()`.

**Step 5: Re-run the focused tests**

Run: `make lua_test`
Expected: Provider tests pass before moving on.

**Step 6: Commit**

Run:
```bash
git add lua/99/providers.lua lua/99/init.lua lua/99/test/providers_spec.lua
git commit -m "feat: port fork providers to upstream base"
```

### Task 3: Rebuild Fill In Function With TDD

**Files:**
- Create: `lua/99/ops/fill-in-function.lua`
- Modify: `lua/99/ops/init.lua`
- Modify: `lua/99/init.lua`
- Modify: `lua/99/prompt-settings.lua`
- Test: `lua/99/test/fill_in_function_spec.lua`
- Test: `lua/99/test/test_utils.lua`

**Step 1: Write the first failing test for direct fill-in**

Cover one behavior only: calling `_99.fill_in_function()` on a function with an empty body creates an upstream prompt request and writes the returned body into the function.

**Step 2: Run the test and verify the failure reason**

Run: `make lua_test`
Expected: Failure is due to missing API/op, not broken test setup.

**Step 3: Implement the minimal op**

Create `lua/99/ops/fill-in-function.lua` to:
- derive current function bounds via treesitter/query helpers
- build request text from current file/function context
- invoke the upstream provider flow
- replace only the function body region

**Step 4: Re-run the focused test**

Run: `make lua_test`
Expected: The initial fill-in test passes.

**Step 5: Add a failing test for prompt-enhanced fill-in**

Cover `_99.fill_in_function_prompt()` capturing user input and routing through the same op with `additional_prompt` appended.

**Step 6: Run the test and verify the failure**

Run: `make lua_test`
Expected: Failure shows the prompt path is not wired yet.

**Step 7: Implement the prompt variant minimally**

Wire upstream capture UI to the same internal fill-in function op.

**Step 8: Add failing tests for edge handling**

Cover:
- missing parser/query support surfaces a clear error
- output fences/explanations are stripped or rejected according to chosen design
- indentation is preserved for inserted body text

**Step 9: Implement the smallest changes to satisfy those tests**

Update prompts and response handling only as far as tests require.

**Step 10: Run the relevant test suite**

Run: `make lua_test`
Expected: Fill-in tests pass and no existing visual/search tests regress.

**Step 11: Commit**

Run:
```bash
git add lua/99/ops/fill-in-function.lua lua/99/ops/init.lua lua/99/init.lua lua/99/prompt-settings.lua lua/99/test/fill_in_function_spec.lua lua/99/test/test_utils.lua
git commit -m "feat: restore fill-in function on upstream prompts"
```

### Task 4: Documentation And User-Facing Setup

**Files:**
- Modify: `README.md`
- Modify: docs generated sources only if needed

**Step 1: Write failing docs expectations mentally, then update docs minimally**

Document:
- new providers
- `fill_in_function` and `fill_in_function_prompt`
- `doctor()`

**Step 2: Regenerate docs only if required by repo conventions**

Run any documented generation command if README is generated from sources.

**Step 3: Verify docs and examples match actual API**

Run: `git diff -- README.md docs/`
Expected: Documentation reflects implemented behavior only.

**Step 4: Commit**

Run:
```bash
git add README.md docs/
git commit -m "docs: describe merged fork functionality"
```

### Task 5: Final Verification And Push

**Files:**
- Verify entire worktree

**Step 1: Run full verification**

Run: `make pr_ready`
Expected: All checks pass, or the exact missing-environment blockers are known.

**Step 2: Run focused smoke verification**

Run any targeted `make lua_test` checks needed for the ported API.

**Step 3: Review git state**

Run:
```bash
git status --short
git log --oneline --decorate -5
```
Expected: Clean worktree and coherent commit history.

**Step 4: Push**

Run: `git push`
Expected: Remote branch updated with all commits.
