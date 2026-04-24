# LazyVim Workflow Improvement Design

Date: 2026-04-23
Status: Draft for review

## Goal

Improve the daily editing experience of this LazyVim config with speed as the top priority.

Secondary goals:

- improve file and project movement
- improve terminal and git flow inside Neovim
- keep the config small, readable, and teachable

This work should favor high-leverage workflow changes over broad customization. The repo should remain easy to understand for someone learning how LazyVim is extended.

## Non-Goals

- replacing LazyVim's overall structure or defaults
- turning the config into a heavy IDE-style setup
- adding broad language-specific custom behavior unrelated to workflow speed
- refactoring unrelated plugin specs or repo structure

## Current State

The current config is intentionally minimal:

- `lua/plugins/ui.lua` contains colorschemes and `smart-splits.nvim`
- `lua/plugins/coding.lua` contains a focused `blink.cmp` tweak
- `lua/plugins/others.lua` contains a small `trouble.nvim` override and a compatibility `nvim-cmp` emoji source
- `lua/config/options.lua`, `lua/config/keymaps.lua`, and `lua/config/autocmds.lua` are empty placeholders

The repo already uses LazyVim extras for multiple languages and utilities, but the local config does not yet strongly optimize the workflows the user described:

- navigation across Zellij panes and Neovim windows
- fast movement between project files and working sets
- smoother terminal and git access without leaving the editor

## Design Principles

- Prefer LazyVim-native primitives before adding parallel toolchains.
- Prefer one strong plugin per workflow gap over several overlapping plugins.
- Put editor behavior in `lua/config/*` when it is not plugin-specific.
- Keep plugin specs declarative and close to the nearest existing topical file.
- Add short comments only where the behavioral change is not obvious.

## Chosen Approach

Use a workflow-first enhancement pass built around the existing LazyVim stack.

This approach keeps the current minimal style, adds only a few plugins, and improves day-to-day speed in the areas the user prioritized: navigation and windows, file and project movement, and terminal and git flow.

## Planned Changes

### 1. Navigation and Window Flow

Keep `smart-splits.nvim` as the core navigation bridge because it already fits the user's Zellij workflow.

Planned improvements:

- keep split movement and resize mappings explicit and easy to remember
- add a small number of complementary window-management keymaps in `lua/config/keymaps.lua` where LazyVim defaults are not enough
- avoid adding a second pane-navigation plugin

Expected result:

- movement between Neovim splits and Zellij panes stays seamless
- window operations feel more deliberate in both Zellij and a plain terminal

### 2. File and Project Flow

Promote the existing LazyVim `Snacks` ecosystem into the primary picker and explorer layer.

Planned improvements:

- enable `snacks_picker` and `snacks_explorer`
- make project, buffer, recent-file, grep, and root-aware file switching first-class
- add `grapple.nvim` for a stable working set of frequently revisited files

Rationale:

- `Snacks` is already in the lockfile and is a first-class LazyVim path
- richer pickers and panels match the user's preference better than a purely minimal fuzzy flow
- `grapple` complements pickers by solving repeated file hopping instead of discovery

Expected result:

- faster switching between files, recent files, buffers, and projects
- less friction when moving among a small set of active files
- no need for a heavier project/session manager at this stage

### 3. Terminal and Git Flow

Use `Snacks.terminal()` as the terminal foundation instead of introducing a separate terminal manager.

Planned improvements:

- make root-dir and cwd terminal entrypoints explicit
- improve terminal-related keymaps for quick command bursts
- keep `lazygit` as the primary git action surface when available
- add `diffview.nvim` for in-editor diff and history review

Rationale:

- a second terminal manager would overlap with LazyVim's built-in direction
- `diffview.nvim` adds a meaningful git review surface that is different from both `gitsigns` and `lazygit`

Expected result:

- faster short terminal interactions from inside Neovim
- less context switching for reviewing changes and file history

### 4. Config Structure Cleanup

Use the repo's existing file layout instead of creating new organizational layers.

Planned file ownership:

- `lua/plugins/ui.lua`: colorschemes, `smart-splits`, picker/explorer-related UI plugins
- `lua/plugins/others.lua`: git workflow additions and small utility plugins
- `lua/config/keymaps.lua`: non-plugin-specific workflow mappings
- `lua/config/options.lua`: small speed-oriented behavior defaults
- `lua/config/autocmds.lua`: only lightweight workflow autocmds if clearly justified

Expected result:

- better separation between plugin specs and editor behavior
- a config that remains easy to trace and teach from

## Plugin Decisions

### Add

- `folke/snacks.nvim` extras for picker and explorer behavior
- `cbochs/grapple.nvim` for tagged working-set navigation
- `sindrets/diffview.nvim` for in-editor diff review

### Keep

- `mrjones2014/smart-splits.nvim`
- `saghen/blink.cmp`
- current colorscheme setup centered on `everforest`

### Avoid for now

- heavyweight project or session managers
- alternate picker stacks such as Telescope or fzf-lua
- separate terminal managers that duplicate `Snacks.terminal()`
- large UI frameworks unrelated to the requested workflows

## Risks and Mitigations

### Risk: overlapping keymaps with LazyVim defaults

Mitigation:

- inspect existing LazyVim mappings before adding new ones
- prefer extending established prefixes over inventing unrelated map clusters

### Risk: plugin overlap or unnecessary complexity

Mitigation:

- add only plugins that cover distinct workflow gaps
- avoid multiple plugins solving the same picker, pane, or terminal problem

### Risk: degrading the teaching-oriented clarity of the repo

Mitigation:

- keep code comments short and behavioral
- keep changes localized to the existing files
- document any non-obvious behavior in `CLAUDE.md`

## Testing Strategy

This repo has no automated test suite, so verification is behavioral.

Required verification after implementation:

- `stylua .`
- `nvim --headless '+Lazy! sync' +qa` or a comparable non-interactive plugin-load sanity check if supported in this environment
- manual checks for:
  - split and pane navigation
  - picker and explorer entrypoints
  - project switching behavior
  - terminal open and toggle behavior
  - diffview open and close behavior

The implementation should avoid claiming success without at least one headless sanity check plus a clear note on what still needs manual verification in a real interactive Neovim session.

## Implementation Shape

The implementation should be split into small steps:

1. enable the chosen LazyVim extras and add the new plugins
2. add workflow keymaps and small option tweaks
3. update documentation in `CLAUDE.md` so the active customization list stays honest
4. run formatting and sanity verification

## Open Questions Resolved

- Primary priority: everyday speed and editing feel
- Plugin additions: allowed if carefully chosen
- Main workflow targets: navigation and windows, file and project movement, terminal and git flow
- Environment bias: mostly Zellij, sometimes a single terminal
- Picker preference: slightly richer pickers and panels are acceptable
