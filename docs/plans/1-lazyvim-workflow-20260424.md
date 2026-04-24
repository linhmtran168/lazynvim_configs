# LazyVim Workflow Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve everyday editing speed in this LazyVim config by strengthening navigation, file/project switching, and terminal/git workflow without making the repo harder to understand.

**Architecture:** Keep LazyVim as the core framework, lean into its `Snacks` picker/explorer stack, and add only two targeted plugins for repeated-file navigation and diff review. Put plugin declarations in the existing topical plugin files and keep workflow behavior in `lua/config/*` so the config stays readable and teachable.

**Tech Stack:** Neovim, LazyVim, lazy.nvim, Snacks.nvim, smart-splits.nvim, grapple.nvim, diffview.nvim, stylua

---

## File Map

- Modify: `lazyvim.json`
  - Enable the `snacks_picker` and `snacks_explorer` LazyVim extras.
- Modify: `lua/plugins/ui.lua`
  - Keep colorschemes and `smart-splits.nvim`, and add the workflow-navigation plugin spec for `grapple.nvim`.
- Modify: `lua/plugins/others.lua`
  - Keep the existing misc overrides and add `diffview.nvim`.
- Modify: `lua/config/options.lua`
  - Set small workflow-oriented editor defaults and make the picker choice explicit.
- Modify: `lua/config/keymaps.lua`
  - Add user-facing workflow mappings for Grapple, terminal shortcuts, and Diffview without duplicating the entire LazyVim keymap table.
- Modify: `CLAUDE.md`
  - Keep the “active customizations” and workflow guidance honest after the config changes.
- Modify: `lazy-lock.json`
  - Accept the plugin lock updates produced by the sync step.

## Task 1: Enable the LazyVim picker and explorer path

**Files:**
- Modify: `lazyvim.json`
- Modify: `lua/config/options.lua`

- [ ] **Step 1: Add the Snacks extras to `lazyvim.json`**

Insert these entries into the `"extras"` array in `lazyvim.json`:

```json
"lazyvim.plugins.extras.editor.snacks_explorer",
"lazyvim.plugins.extras.editor.snacks_picker"
```

Place them with the other editor extras rather than appending them randomly to the end of the file.

- [ ] **Step 2: Make the picker choice explicit in `lua/config/options.lua`**

Replace the placeholder-only file with:

```lua
-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.lazyvim_picker = "snacks"

vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 8
vim.opt.timeoutlen = 300
```

This keeps the repo’s “small and readable” teaching style while making the chosen picker and movement feel explicit.

- [ ] **Step 3: Run a headless config parse check before syncing plugins**

Run:

```bash
nvim --headless "+qa"
```

Expected:
- exit code `0`
- no Lua syntax errors from `lazyvim.json` or `lua/config/options.lua`

- [ ] **Step 4: Commit the picker/explorer bootstrap**

Run:

```bash
git add lazyvim.json lua/config/options.lua
git commit -m "feat: enable snacks picker and explorer workflow"
```

Expected:
- commit succeeds unless there are unrelated staged changes that need to stay out of scope

## Task 2: Add the focused workflow plugins

**Files:**
- Modify: `lua/plugins/ui.lua`
- Modify: `lua/plugins/others.lua`

- [ ] **Step 1: Add `grapple.nvim` to `lua/plugins/ui.lua`**

Add this spec near the navigation-oriented plugins, keeping the current `smart-splits.nvim` block intact:

```lua
{
  "cbochs/grapple.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    scope = "git",
  },
},
```

Do not move colorscheme specs into a new file. Keep this repo’s existing “one UI file” pattern.

- [ ] **Step 2: Add `diffview.nvim` to `lua/plugins/others.lua`**

Append this spec after the existing `trouble.nvim` and `nvim-cmp` overrides:

```lua
{
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
},
```

Keep the existing `nvim-cmp` compatibility override untouched unless plugin load errors prove it is broken.

- [ ] **Step 3: Run a headless plugin-spec load check**

Run:

```bash
nvim --headless "+Lazy! load grapple.nvim" "+Lazy! load diffview.nvim" "+qa"
```

Expected:
- exit code `0`
- no plugin-spec parse errors from `ui.lua` or `others.lua`

- [ ] **Step 4: Commit the plugin additions**

Run:

```bash
git add lua/plugins/ui.lua lua/plugins/others.lua
git commit -m "feat: add workflow navigation and diff plugins"
```

Expected:
- commit succeeds with only the intended plugin-spec changes staged

## Task 3: Add workflow keymaps for file hopping, terminal access, and diff review

**Files:**
- Modify: `lua/config/keymaps.lua`

- [ ] **Step 1: Replace the placeholder-only file with focused workflow keymaps**

Replace the placeholder content in `lua/config/keymaps.lua` with:

```lua
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>m", function()
  require("grapple").toggle()
end, { desc = "Toggle File Tag" })

map("n", "<leader>M", function()
  require("grapple").toggle_tags()
end, { desc = "Open File Tags" })

map("n", "]m", function()
  require("grapple").cycle_tags("next")
end, { desc = "Next File Tag" })

map("n", "[m", function()
  require("grapple").cycle_tags("prev")
end, { desc = "Prev File Tag" })

map("n", "<leader>1", function()
  require("grapple").select({ index = 1 })
end, { desc = "Jump to Tag 1" })

map("n", "<leader>2", function()
  require("grapple").select({ index = 2 })
end, { desc = "Jump to Tag 2" })

map("n", "<leader>3", function()
  require("grapple").select({ index = 3 })
end, { desc = "Jump to Tag 3" })

map("n", "<leader>4", function()
  require("grapple").select({ index = 4 })
end, { desc = "Jump to Tag 4" })

map({ "n", "t" }, "<A-`>", function()
  Snacks.terminal()
end, { desc = "Terminal (cwd)" })

map("n", "<leader>t`", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (root dir)" })

map("n", "<leader>gvo", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
map("n", "<leader>gvc", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
map("n", "<leader>gvf", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview File History" })
map("n", "<leader>gvh", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview Repo History" })
```

This keeps new workflow behavior in the canonical `lua/config/keymaps.lua` extension point instead of scattering keymaps through multiple plugin specs.

- [ ] **Step 2: Run a headless keymap sanity check**

Run:

```bash
nvim --headless "+lua print(vim.fn.maparg('<leader>m', 'n') ~= '')" "+lua print(vim.fn.maparg('<leader>gvo', 'n') ~= '')" "+qa"
```

Expected output:

```text
true
true
```

- [ ] **Step 3: Run an interaction smoke check for the new commands**

Run:

```bash
nvim --headless "+lua require('grapple').toggle()" "+lua require('grapple').toggle()" "+DiffviewOpen" "+DiffviewClose" "+qa"
```

Expected:
- exit code `0`
- no “module not found” or command-not-found errors

- [ ] **Step 4: Commit the workflow keymaps**

Run:

```bash
git add lua/config/keymaps.lua
git commit -m "feat: add workflow keymaps for navigation and git review"
```

Expected:
- commit succeeds with only the keymap file staged

## Task 4: Sync plugins and capture the lockfile changes

**Files:**
- Modify: `lazy-lock.json`

- [ ] **Step 1: Sync the plugin set**

Run:

```bash
nvim --headless "+Lazy! sync" "+qa"
```

Expected:
- new plugins are installed
- `lazy-lock.json` updates to include any new pinned commits

- [ ] **Step 2: Verify the new plugins are pinned in `lazy-lock.json`**

Run:

```bash
rg -n '"grapple.nvim"|"diffview.nvim"' lazy-lock.json
```

Expected output:
- one match for `"grapple.nvim"`
- one match for `"diffview.nvim"`

- [ ] **Step 3: Commit the lockfile update**

Run:

```bash
git add lazy-lock.json
git commit -m "chore: refresh lazy lockfile for workflow plugins"
```

Expected:
- commit succeeds with only the lockfile changes staged

## Task 5: Update the repo documentation

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the “Active customizations” section**

Add one-line rationale entries for:

- `Snacks` picker and explorer becoming the primary file/project surface
- `grapple.nvim` as the working-set file hopper
- `diffview.nvim` as the in-editor diff/history review surface

Use the existing style, for example:

```md
- **Picker and explorer — `Snacks`** (`lazyvim.json`). `snacks_picker` and `snacks_explorer` become the primary file/project navigation surface so recent files, project switching, grep, and an explorer panel all use the same LazyVim-native stack.
- **Working set — `grapple.nvim`** (`lua/plugins/ui.lua`, `lua/config/keymaps.lua`). Use tags for the handful of files you bounce between repeatedly; this complements pickers by solving fast return trips instead of discovery.
- **Diff review — `diffview.nvim`** (`lua/plugins/others.lua`, `lua/config/keymaps.lua`). Keep `lazygit` for active repo operations, but use Diffview when you want in-editor diff and file-history review without leaving Neovim.
```

- [ ] **Step 2: Update the commands or conventions section where needed**

Add short notes for the new user-facing actions:

```md
- `:DiffviewOpen` / `:DiffviewFileHistory` — review repo diffs and file history inside Neovim.
- `<leader>m`, `<leader>M`, `[m`, `]m` — tag, list, and cycle through the current working set with Grapple.
```

- [ ] **Step 3: Run a quick documentation sanity pass**

Run:

```bash
rg -n "Snacks|grapple|diffview" CLAUDE.md
```

Expected:
- matches for all three new workflow surfaces

- [ ] **Step 4: Commit the documentation update**

Run:

```bash
git add CLAUDE.md
git commit -m "docs: document workflow-focused lazyvim customizations"
```

Expected:
- commit succeeds with only the documentation update staged

## Task 6: Final formatting and verification

**Files:**
- Modify: `lua/config/options.lua`
- Modify: `lua/config/keymaps.lua`
- Modify: `lua/plugins/ui.lua`
- Modify: `lua/plugins/others.lua`
- Modify: `CLAUDE.md`
- Modify: `lazyvim.json`
- Modify: `lazy-lock.json`

- [ ] **Step 1: Format the Lua changes**

Run:

```bash
stylua lua
```

Expected:
- exit code `0`
- only Lua formatting changes in tracked files

- [ ] **Step 2: Run a full headless startup sanity check**

Run:

```bash
nvim --headless "+checkhealth" "+qa"
```

Expected:
- exit code `0`
- no startup crash caused by the new config

- [ ] **Step 3: Run a focused workflow smoke check**

Run:

```bash
nvim --headless "+lua Snacks.picker.projects()" "+lua Snacks.explorer({ cwd = LazyVim.root() })" "+lua require('grapple').toggle()" "+DiffviewOpen" "+DiffviewClose" "+qa"
```

Expected:
- exit code `0`
- no errors loading the picker, explorer, Grapple, or Diffview entrypoints

- [ ] **Step 4: Review the final diff**

Run:

```bash
git diff -- lazyvim.json lazy-lock.json lua/config/options.lua lua/config/keymaps.lua lua/plugins/ui.lua lua/plugins/others.lua CLAUDE.md
```

Expected:
- diff stays within the approved workflow scope
- no unrelated refactors appear

- [ ] **Step 5: Create the final implementation commit**

Run:

```bash
git add lazyvim.json lazy-lock.json lua/config/options.lua lua/config/keymaps.lua lua/plugins/ui.lua lua/plugins/others.lua CLAUDE.md
git commit -m "feat: improve lazyvim workflow for navigation and git"
```

Expected:
- one final scoped feature commit if the intermediate commits were intentionally skipped

## Self-Review

- Spec coverage:
  - navigation and window flow is covered by `smart-splits` retention plus workflow keymaps in Task 3
  - file and project flow is covered by `snacks_picker`, `snacks_explorer`, and `grapple.nvim` in Tasks 1-3
  - terminal and git flow is covered by terminal keymaps and `diffview.nvim` in Tasks 2-3
  - documentation and verification are covered by Tasks 5-6
- Placeholder scan:
  - no unresolved placeholder markers remain
- Type and API consistency:
  - the plan consistently uses `require("grapple").toggle`, `toggle_tags`, `cycle_tags`, and `select`
  - the plan consistently uses `Snacks.terminal`, `Snacks.picker.projects`, and `Snacks.explorer`
