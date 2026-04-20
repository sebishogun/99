# Upstream Port Design

**Goal:** Base the fork on current `ThePrimeagen/99` and layer fork-only functionality on top without restoring the old request stack.

**Decision:** Use upstream's `Prompt`, `State`, tracking, status window, and provider architecture as the only request path. Reintroduce fork features as upstream-native extensions.

## Scope

- Keep upstream workflow APIs and architecture as the foundation.
- Re-add fork providers and runtime diagnostics.
- Reimplement `fill_in_function` and `fill_in_function_prompt` on the upstream prompt/request model.
- Keep prompt improvements focused on code-only output and better function implementation quality.

## Architecture

### Upstream Base

- Keep upstream `lua/99/init.lua`, `lua/99/prompt.lua`, `lua/99/state.lua`, `lua/99/providers.lua`, tracking, status window, completions, and picker integrations as the base.
- New functionality must plug into that flow instead of reviving `RequestContext` or the old language module tree.

### Fork Additions

- Provider/runtime additions:
  - `CopilotCLIProvider`
  - `CodexProvider`
  - preferred Gemini/OpenCode defaults where still correct
  - `doctor()` diagnostic entrypoint
- Editing additions:
  - `_99.fill_in_function(opts?)`
  - `_99.fill_in_function_prompt(opts?)`

### Fill In Function

- Implement a new upstream-style operation module for function-body generation.
- Build a `Prompt` from current editor state, detect the current function range with treesitter, and extract enough surrounding text to generate only the missing implementation.
- Use one shared internal implementation for both direct and prompted variants.
- Route requests through upstream provider execution, tracking, logging, and status display.
- Apply returned code only to the target function body/range.
- Fail clearly when treesitter parser/query support is unavailable.

## Prompting

- Preserve the fork's stronger prompt behavior.
- Require code-only output, no markdown fences, no explanations.
- Keep prompts language-aware where current filetype and tree context are sufficient.
- Prefer minimal implementation matching existing indentation and local style.

## Testing Strategy

- Add failing tests first for new providers and `fill_in_function` behavior.
- Cover treesitter detection, prompt capture routing, and writeback behavior.
- Verify plugin loads with the merged API surface.
- Run project verification as far as local tooling allows, noting any missing host dependencies.

## Merge Strategy

- Work on top of upstream `master` in an isolated worktree.
- Commit incrementally:
  - worktree/setup docs
  - provider/runtime port
  - fill-in-function port
  - docs and verification fixes
- Push the feature branch as progress is made.
