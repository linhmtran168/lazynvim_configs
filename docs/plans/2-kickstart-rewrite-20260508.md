# Kickstart-style Modular Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace LazyVim + lazy.nvim with a modular, heavily-commented Neovim configuration that uses native `vim.pack` and `tree-sitter-manager.nvim`, while preserving the user's daily feature set. Ship via `NVIM_APPNAME=nvim-kickstart` side-channel so the current LazyVim editor remains the daily driver until cutover.

**Architecture:** Domain-modular Lua tree under `lua/{config,plugins,plugins/lang}`. Single plugin manifest in `lua/config/pack.lua`. Per-language modules return a fixed shape, aggregated by `lua/config/lang.lua`, consumed by `plugins/{lsp,coding,treesitter}.lua`. Rollout uses a git worktree + symlink + `NVIM_APPNAME`. Cutover is a single commit on `main`.

**Tech Stack:** Neovim 0.12+, `vim.pack`, `tree-sitter-manager.nvim`, `mason` + `mason-lspconfig` + `nvim-lspconfig`, `conform.nvim`, `nvim-lint`, `blink.cmp`, `snacks.nvim`, `everforest`, `lualine`, `mini.*`, `smart-splits`, `grapple`, `gitsigns`, `diffview`, `copilot.lua` + `CopilotChat`.

**Reference:** Design spec at `docs/specs/2-kickstart-rewrite-design-20260508.md`. Read it before starting; this plan implements its decisions.

**Verification model:** This repo has no test framework. "Tests" in this plan are manual smoke checks using `nvk --headless +qa` (boot exits 0), `:checkhealth`, and targeted feature verification. Each task ends with an explicit verification step + commit.

**Path conventions used in this plan:**
- `<repo>` → `~/.config/nvim-kickstart-worktree` (the worktree where work happens). Resolves to a real path after Task 2.
- `<config>` → `~/.config/nvim-kickstart` (symlink). What `NVIM_APPNAME=nvim-kickstart` resolves to.
- `<data>` → `~/.local/share/nvim-kickstart` (auto-created by Neovim from `NVIM_APPNAME`).
- `nvk` → shell alias `NVIM_APPNAME=nvim-kickstart nvim`. Defined in Task 3.

---

## Phase 0 — Branch and side-channel setup

### Task 1: Create the feature branch

**Files:**
- Modify: git ref (no file changes)

- [ ] **Step 1: Confirm working tree is clean on `main`**

```bash
cd ~/.config/nvim
git status
```

Expected: clean (or only the AGENTS.md / CLAUDE.md / docs changes from the brainstorm session, which we will commit before branching).

- [ ] **Step 2: Commit any spec/plan/claude-md changes from the design session**

```bash
cd ~/.config/nvim
git status
git add docs/specs/2-kickstart-rewrite-design-20260508.md \
        docs/plans/2-kickstart-rewrite-20260508.md \
        CLAUDE.md AGENTS.md
git commit -m "$(cat <<'EOF'
docs: add kickstart-rewrite spec and plan

Design and implementation plan for replacing LazyVim with a modular
vim.pack-based config. CLAUDE.md updated with deeper expertise framing.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: commit created on `main`.

- [ ] **Step 3: Create the feature branch (without checking it out — we will work on it via the worktree)**

```bash
cd ~/.config/nvim
git branch feature/kickstart-rewrite main
git branch --list feature/kickstart-rewrite
```

Expected: `feature/kickstart-rewrite` branch exists; `main` is still the checked-out branch.

---

### Task 2: Create the side-channel worktree (CONFIRMATION GATE)

**Files:**
- Create: `~/.config/nvim-kickstart-worktree/` (worktree directory, populated by git)
- Create: `~/.config/nvim-kickstart` (symlink)

**⚠ CONFIRMATION GATE:** Per the user's global preference, **do not run `git worktree add` without explicit user confirmation each time.** Before Step 1, ask the user: "About to run `git worktree add ~/.config/nvim-kickstart-worktree feature/kickstart-rewrite`. OK to proceed?" Wait for explicit yes.

- [ ] **Step 1 (after confirmation): Create the worktree**

```bash
cd ~/.config/nvim
git worktree add ~/.config/nvim-kickstart-worktree feature/kickstart-rewrite
```

Expected: `Preparing worktree (checking out 'feature/kickstart-rewrite')` then `HEAD is now at <sha>`.

- [ ] **Step 2: Symlink for `NVIM_APPNAME` resolution**

```bash
ln -s ~/.config/nvim-kickstart-worktree ~/.config/nvim-kickstart
ls -la ~/.config/nvim-kickstart
```

Expected: symlink points to the worktree.

- [ ] **Step 3: Verify Neovim resolves `NVIM_APPNAME=nvim-kickstart` to the worktree**

```bash
NVIM_APPNAME=nvim-kickstart nvim --headless +'echo stdpath("config")' +qa 2>&1
```

Expected output: `/Users/<you>/.config/nvim-kickstart` (or however the home path resolves).

- [ ] **Step 4: Verify the worktree starts on `feature/kickstart-rewrite` with the same files as `main`**

```bash
cd ~/.config/nvim-kickstart-worktree
git branch --show-current
ls
```

Expected: `feature/kickstart-rewrite`; same file listing as `main`.

- [ ] **Step 5: No commit needed for this task** (filesystem-only setup; nothing to add to git).

---

### Task 3: Define the `nvk` shell alias

**Files:**
- Modify: `~/.config/fish/config.fish` (or equivalent for the user's shell)

- [ ] **Step 1: Detect the user's shell and config file**

```bash
echo $SHELL
ls ~/.config/fish/config.fish 2>/dev/null && echo "fish config exists"
```

Expected: `/opt/homebrew/bin/fish` per the environment; `fish config exists`.

- [ ] **Step 2: Append the alias to fish config**

```bash
cat >> ~/.config/fish/config.fish <<'EOF'

# nvk: launch the kickstart rewrite of nvim via NVIM_APPNAME side-channel.
# See ~/.config/nvim-kickstart/CLAUDE.md (after cutover, this becomes the default).
alias nvk='NVIM_APPNAME=nvim-kickstart nvim'
EOF
```

- [ ] **Step 3: Verify the alias works in a new shell**

Run in a new fish session:

```bash
type nvk
nvk --headless +'echo stdpath("config")' +qa
```

Expected: `nvk is a function...`; path output is `~/.config/nvim-kickstart`.

- [ ] **Step 4: No commit** (the shell config is outside the repo).

---

## Phase 1 — Empty bootable skeleton

### Task 4: Wipe the LazyVim files in the worktree, write the orchestrator skeleton

**Files:**
- Delete (in worktree only): `lazy-lock.json`, `lazyvim.json`, `lua/config/lazy.lua`, `lua/plugins/coding.lua`, `lua/plugins/others.lua`, `lua/plugins/ui.lua`, `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`
- Modify: `<repo>/init.lua`
- Create: `<repo>/lua/config/init.lua`

- [ ] **Step 1: Delete LazyVim-era files in the worktree (only)**

```bash
cd ~/.config/nvim-kickstart-worktree
git rm lazy-lock.json lazyvim.json \
       lua/config/lazy.lua \
       lua/config/options.lua \
       lua/config/keymaps.lua \
       lua/config/autocmds.lua \
       lua/plugins/coding.lua \
       lua/plugins/others.lua \
       lua/plugins/ui.lua
```

Expected: files staged for deletion. (`~/.config/nvim/` on `main` is **untouched** — verify with `cd ~/.config/nvim && git status` showing clean.)

- [ ] **Step 2: Rewrite `<repo>/init.lua` to the one-liner**

Replace contents with:

```lua
-- Entry point. All real wiring lives in lua/config/init.lua.
-- See docs/specs/2-kickstart-rewrite-design-20260508.md for architecture.
require('config')
```

- [ ] **Step 3: Create `<repo>/lua/config/init.lua` orchestrator**

```lua
-- ============================================================================
-- Boot orchestrator — the single entry point that wires the whole config.
-- Read top-to-bottom: each step's order matters. See the design spec §5.2.
-- ============================================================================

-- 1. Set leader BEFORE any plugin spec evaluates `keys = { ... }`.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- 2. Editor options first so plugin setup() observes the right values.
require('config.options')

-- 3. Aggregate language modules (pure data; no side effects).
--    `config.lang` reads every lua/plugins/lang/*.lua and merges them
--    into a single table consumed by lsp / coding / treesitter modules.
local lang = require('config.lang')

-- 4. Install / update plugins via vim.pack. Blocking on first run while
--    repos are git-cloned. Subsequent runs: ~instant, no network.
require('config.pack')

-- 5. Plugin modules in load order. Each `require` is pcall-wrapped so a
--    single broken module surfaces an error but doesn't abort startup.
local function load(mod)
  local ok, err = pcall(require, mod)
  if not ok then
    vim.notify(('module %s failed: %s'):format(mod, err), vim.log.levels.ERROR)
  end
end

load('plugins.colorscheme')   -- first so subsequent setups hash correct hl groups
load('plugins.treesitter')    -- early so plugins assuming TS find it ready
load('plugins.ui')
load('plugins.editor')
load('plugins.coding')
load('plugins.picker')
load('plugins.git')
load('plugins.ai')
load('plugins.lsp')           -- last among plugins; reads `lang` for servers

-- 6. Keymaps after plugins so user commands defined by plugins exist.
require('config.keymaps')
require('config.autocmds')

-- Expose `lang` for diagnostic poking via `:lua = require('config.lang')`.
return { lang = lang }
```

- [ ] **Step 4: Verify the orchestrator parses without crashing**

```bash
nvk --headless +'lua print("ok")' +qa 2>&1
```

Expected output: `ok` plus errors for missing `config.options`, `config.lang`, `config.pack`, `config.keymaps`, `config.autocmds`, and each `plugins.*` module — these are expected at this stage; the orchestrator must not abort.

- [ ] **Step 5: Stage and commit the skeleton**

```bash
cd ~/.config/nvim-kickstart-worktree
git add init.lua lua/config/init.lua
git commit -m "$(cat <<'EOF'
feat: introduce orchestrator skeleton

Wipes LazyVim-era files from the rewrite branch and lays down init.lua
plus lua/config/init.lua. Subsequent tasks fill in the modules the
orchestrator loads.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Write `lua/config/options.lua`

**Files:**
- Create: `<repo>/lua/config/options.lua`

- [ ] **Step 1: Create the options module**

```lua
-- ============================================================================
-- Editor options. Values mirror what kickstart.nvim sets, with extras for
-- a daily-driver workflow. Each block has a comment explaining the *why*.
-- ============================================================================

local opt = vim.opt

-- Line numbers: absolute on the cursor line, relative elsewhere — fastest
-- way to jump with `5j`/`12k` motions without counting from line 1.
opt.number = true
opt.relativenumber = true

-- System clipboard integration. macOS: `osascript`/`pbcopy` already wired by nvim.
-- We schedule the option write so startup isn't blocked on clipboard provider lookup.
vim.schedule(function() opt.clipboard = 'unnamedplus' end)

-- Search: case-insensitive unless query has uppercase ("smart").
opt.ignorecase = true
opt.smartcase = true

-- Wrapped lines indent visually under their start column — readable prose.
opt.breakindent = true

-- Persistent undo across sessions; lives in <data>/undo/.
opt.undofile = true

-- Keep some context around the cursor when scrolling.
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Show diagnostics column always so text doesn't shift when one appears.
opt.signcolumn = 'yes'

-- Faster CursorHold (used by LSP for hover popups, gitsigns blame, etc.).
opt.updatetime = 250

-- which-key-style timeout for partial mappings.
opt.timeoutlen = 300

-- Splits: open right and below by default; less surprising than the vim defaults.
opt.splitright = true
opt.splitbelow = true

-- Show special characters: tabs as "→ ", trailing spaces as "·", non-breaking as "␣".
opt.list = true
opt.listchars = { tab = '→ ', trail = '·', nbsp = '␣' }

-- Live preview of substitutions in a split (`:%s/foo/bar` — see what'd change).
opt.inccommand = 'split'

-- Highlight the cursor line so the cursor is locatable in long files.
opt.cursorline = true

-- True color — required by everforest and most modern colorschemes.
opt.termguicolors = true

-- Reasonable tabbing defaults; ftplugins override per language.
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true

-- No swapfiles; we have undofile + git for recovery.
opt.swapfile = false

-- Disable some built-in plugins we don't use to shave a millisecond or two.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
```

- [ ] **Step 2: Verify the module loads**

```bash
nvk --headless +'lua require("config.options")' +'echo &number &relativenumber' +qa 2>&1
```

Expected: `2 1` (or similar — both options enabled).

- [ ] **Step 3: Commit**

```bash
cd ~/.config/nvim-kickstart-worktree
git add lua/config/options.lua
git commit -m "feat(config): add options.lua with annotated defaults

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Write `lua/config/lang.lua` aggregator

**Files:**
- Create: `<repo>/lua/config/lang.lua`

- [ ] **Step 1: Create the aggregator (handles empty `lang/` directory gracefully)**

```lua
-- ============================================================================
-- Language aggregator.
--
-- Reads every lua/plugins/lang/*.lua file. Each language module returns a
-- table with the shape:
--
--   {
--     servers          = { <lspconfig-name> = { settings = {...} } },
--     formatters_by_ft = { <ft> = { 'formatter1', 'formatter2' } },
--     linters_by_ft    = { <ft> = { 'linter1' } },
--     parsers          = { 'parser1', 'parser2' },
--     mason_tools      = { 'gopls', 'gofumpt', ... },
--     extra_plugins    = { { src = '...' }, ... },
--   }
--
-- All fields are optional. This module merges them into one table consumed
-- by plugins/{lsp,coding,treesitter}.lua and config/pack.lua.
-- ============================================================================

local M = {
  servers = {},
  formatters_by_ft = {},
  linters_by_ft = {},
  parsers = {},
  mason_tools = {},
  extra_plugins = {},
}

local lang_dir = vim.fn.stdpath('config') .. '/lua/plugins/lang'

-- vim.fn.readdir returns {} if the directory doesn't exist yet; safe.
for _, file in ipairs(vim.fn.readdir(lang_dir, [[v:val =~ '\.lua$']])) do
  local name = file:match('(.+)%.lua$')
  local ok, mod = pcall(require, 'plugins.lang.' .. name)
  if ok and type(mod) == 'table' then
    for k, v in pairs(mod.servers or {})          do M.servers[k] = v end
    for k, v in pairs(mod.formatters_by_ft or {}) do M.formatters_by_ft[k] = v end
    for k, v in pairs(mod.linters_by_ft or {})    do M.linters_by_ft[k] = v end
    for _, p in ipairs(mod.parsers or {})         do table.insert(M.parsers, p) end
    for _, t in ipairs(mod.mason_tools or {})     do table.insert(M.mason_tools, t) end
    for _, e in ipairs(mod.extra_plugins or {})   do table.insert(M.extra_plugins, e) end
  elseif not ok then
    vim.notify(('lang module %s failed: %s'):format(name, mod), vim.log.levels.WARN)
  end
end

return M
```

- [ ] **Step 2: Verify it returns an empty-but-valid table when no lang modules exist**

```bash
nvk --headless +'lua local t=require("config.lang") print(#t.parsers, #t.mason_tools)' +qa 2>&1
```

Expected: `0 0`.

- [ ] **Step 3: Commit**

```bash
git add lua/config/lang.lua
git commit -m "feat(config): add lang.lua aggregator

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Write a stub `lua/config/pack.lua` (no plugins yet)

**Files:**
- Create: `<repo>/lua/config/pack.lua`

- [ ] **Step 1: Stub manifest with only the `:Pack*` user commands**

```lua
-- ============================================================================
-- Plugin manifest. Single source of truth for "what is installed".
--
-- vim.pack.add{} accepts a list of { src=URL, name?=, version?= }. It clones
-- missing plugins into <data>/site/pack/core/ and adds them to runtimepath.
-- It does NOT lazy-load by event — eager. Deferred *configuration* is the
-- responsibility of individual plugin modules (e.g. via FileType autocmds).
--
-- Update primitive: vim.pack.update().
-- ============================================================================

local lang = require('config.lang')

vim.pack.add({
  -- (intentionally empty in the stub; subsequent tasks add plugins here)
})

-- Append per-language extra_plugins so they land in the same install pass.
if lang.extra_plugins and #lang.extra_plugins > 0 then
  vim.pack.add(lang.extra_plugins)
end

-- ----------------------------------------------------------------------------
-- :Pack* commands — minimal lazy.nvim parity.
-- ----------------------------------------------------------------------------

-- :Pack — scratch buffer listing installed plugins with version + status.
vim.api.nvim_create_user_command('Pack', function()
  local lines = { 'Installed plugins (vim.pack.get):', '' }
  for _, p in ipairs(vim.pack.get()) do
    table.insert(lines, ('  %-40s  %s'):format(p.spec.name or p.spec.src, p.active and 'active' or 'inactive'))
  end
  vim.cmd('new')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  vim.cmd('file [Pack]')
end, { desc = 'Show installed plugins' })

-- :PackUpdate — fetch + apply updates for everything in the manifest.
vim.api.nvim_create_user_command('PackUpdate', function()
  vim.pack.update()
end, { desc = 'Update all plugins' })

-- :PackClean — remove plugins present on disk but absent from the manifest.
-- Compares vim.pack.get() against names referenced in the manifest call(s).
vim.api.nvim_create_user_command('PackClean', function()
  -- Implementation deferred until manifest has entries; placeholder.
  vim.notify('PackClean: not yet implemented (manifest is empty)', vim.log.levels.INFO)
end, { desc = 'Remove unmanaged plugins' })

-- :PackLog — tail the most recent update log written by :PackUpdate.
vim.api.nvim_create_user_command('PackLog', function()
  local log = vim.fn.stdpath('data') .. '/pack-update.log'
  if vim.fn.filereadable(log) == 1 then
    vim.cmd('tabnew ' .. log)
  else
    vim.notify('No PackLog yet — run :PackUpdate first', vim.log.levels.INFO)
  end
end, { desc = 'Show last update log' })
```

- [ ] **Step 2: Verify the manifest loads and `:Pack` runs**

```bash
nvk --headless +'Pack' +qa 2>&1
```

Expected: no errors. (The scratch buffer would show "Installed plugins (vim.pack.get):" with no entries.)

- [ ] **Step 3: Commit**

```bash
git add lua/config/pack.lua
git commit -m "feat(config): add empty pack.lua manifest with :Pack* commands

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Write minimal `lua/config/keymaps.lua` and `lua/config/autocmds.lua`

**Files:**
- Create: `<repo>/lua/config/keymaps.lua`
- Create: `<repo>/lua/config/autocmds.lua`

- [ ] **Step 1: Keymaps — universal defaults + plugin-mgmt namespace; LSP/picker keymaps come later in their own modules**

```lua
-- ============================================================================
-- Global keymaps. LSP keymaps live in plugins/lsp.lua's LspAttach callback
-- (buffer-scoped). Picker keymaps live in plugins/picker.lua near the plugin
-- they drive. Custom plugin keymaps (Grapple, smart-splits) live in
-- plugins/editor.lua. This file holds editor-wide leader bindings.
-- ============================================================================

local map = vim.keymap.set

-- ---------- Universal defaults ------------------------------------------------

-- Wrap-aware vertical motion: `j`/`k` on a wrapped line move display rows,
-- not file rows. `5j` (with a count) reverts to file-row motion.
map({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = 'Down' })
map({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = 'Up' })

-- `n`/`N` keep the match centered and unfold so you can read it.
map('n', 'n', "'Nn'[v:searchforward].'zv'", { expr = true, desc = 'Next Search Result' })
map('n', 'N', "'nN'[v:searchforward].'zv'", { expr = true, desc = 'Prev Search Result' })

-- `<esc>` clears search highlight (doesn't unset hlsearch — just hides it).
map('n', '<esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- Save with Ctrl-S in any mode.
map({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

-- Visual indent stays selected.
map('x', '<', '<gv')
map('x', '>', '>gv')

-- Insert-mode undo breakpoints — `u` after typing a paragraph undoes one
-- sentence at a time instead of the whole paragraph.
map('i', ',', ',<c-g>u')
map('i', '.', '.<c-g>u')
map('i', ';', ';<c-g>u')

-- Add comment line above/below current line (gco/gcO).
map('n', 'gco', 'o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Below' })
map('n', 'gcO', 'O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>', { desc = 'Add Comment Above' })

-- ---------- File / quit / splits ----------------------------------------------

map('n', '<leader>fn', '<cmd>enew<cr>',  { desc = 'New File' })
map('n', '<leader>qq', '<cmd>qa<cr>',    { desc = 'Quit All' })
map('n', '<leader>-',  '<C-w>s',         { desc = 'Split Window Below', remap = true })
map('n', '<leader>|',  '<C-w>v',         { desc = 'Split Window Right', remap = true })

-- ---------- Buffers -----------------------------------------------------------

map('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
map('n', '<S-l>', '<cmd>bnext<cr>',     { desc = 'Next Buffer' })
map('n', '[b',    '<cmd>bprevious<cr>', { desc = 'Prev Buffer' })
map('n', ']b',    '<cmd>bnext<cr>',     { desc = 'Next Buffer' })
map('n', '<leader>bb', '<cmd>e #<cr>',  { desc = 'Switch to Other Buffer' })
map('n', '<leader>`',  '<cmd>e #<cr>',  { desc = 'Switch to Other Buffer' })
map('n', '<leader>bd', '<cmd>bdelete<cr>',     { desc = 'Delete Buffer' })
map('n', '<leader>bD', '<cmd>bdelete!<cr>',    { desc = 'Delete Buffer (force)' })
map('n', '<leader>bo', function()
  local cur = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= cur and vim.bo[b].buflisted then vim.api.nvim_buf_delete(b, {}) end
  end
end, { desc = 'Delete Other Buffers' })

-- ---------- Diagnostics & quickfix --------------------------------------------

map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Line Diagnostics' })
map('n', ']d', function() vim.diagnostic.jump({ count = 1 })  end, { desc = 'Next Diagnostic' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, { desc = 'Prev Diagnostic' })
map('n', ']e', function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })  end, { desc = 'Next Error' })
map('n', '[e', function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end, { desc = 'Prev Error' })
map('n', ']w', function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN })   end, { desc = 'Next Warning' })
map('n', '[w', function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN })  end, { desc = 'Prev Warning' })
map('n', '[q', vim.cmd.cprev, { desc = 'Prev Quickfix' })
map('n', ']q', vim.cmd.cnext, { desc = 'Next Quickfix' })

-- ---------- Format toggle (conform.nvim respects these flags) -----------------

map('n', '<leader>uf', function()
  vim.b.disable_autoformat = not vim.b.disable_autoformat
  vim.notify(('Autoformat (buffer): %s'):format(vim.b.disable_autoformat and 'OFF' or 'ON'))
end, { desc = 'Toggle Autoformat (buffer)' })
map('n', '<leader>uF', function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify(('Autoformat (global): %s'):format(vim.g.disable_autoformat and 'OFF' or 'ON'))
end, { desc = 'Toggle Autoformat (global)' })

-- ---------- Plugin & parser management ----------------------------------------

map('n', '<leader>ll', '<cmd>Pack<cr>',       { desc = 'Plugin Manager' })
map('n', '<leader>lu', '<cmd>PackUpdate<cr>', { desc = 'Plugin: Update all' })
map('n', '<leader>lc', '<cmd>PackClean<cr>',  { desc = 'Plugin: Clean unused' })
map('n', '<leader>lL', '<cmd>PackLog<cr>',    { desc = 'Plugin: Last update log' })
-- <leader>lt* (treesitter manager) is set in plugins/treesitter.lua.
```

- [ ] **Step 2: Autocmds — yank highlight, restore cursor, trim trailing whitespace**

```lua
-- ============================================================================
-- Autocmds. Each group uses `clear = true` so re-`require`-ing this module
-- (e.g. via :source %) doesn't double-register handlers.
-- ============================================================================

local function group(name) return vim.api.nvim_create_augroup('config_' .. name, { clear = true }) end

-- Briefly highlight yanked text — visual confirmation that the yank happened.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = group('yank_highlight'),
  callback = function() vim.hl.on_yank({ timeout = 200 }) end,
})

-- Restore cursor to its last position when reopening a file.
vim.api.nvim_create_autocmd('BufReadPost', {
  group = group('restore_cursor'),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Resize splits when the host terminal resizes (e.g. tmux/Zellij window).
vim.api.nvim_create_autocmd('VimResized', {
  group = group('resize_splits'),
  command = 'tabdo wincmd =',
})

-- Auto-create parent directories on :w of a path that doesn't exist yet.
vim.api.nvim_create_autocmd('BufWritePre', {
  group = group('mkdir_on_save'),
  callback = function(ev)
    if ev.match:match('^%w+://') then return end  -- skip URI-style buffers
    local dir = vim.fn.fnamemodify(ev.file, ':p:h')
    if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, 'p') end
  end,
})
```

- [ ] **Step 3: Verify a clean headless boot**

```bash
nvk --headless +qa 2>&1
echo "Exit code: $?"
```

Expected: no error output; exit code `0`.

- [ ] **Step 4: Commit**

```bash
git add lua/config/keymaps.lua lua/config/autocmds.lua
git commit -m "feat(config): add keymaps and autocmds (universal + plugin-mgmt)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2 — Colorscheme (first plugin lands)

### Task 9: Add `everforest-nvim` and `lua/plugins/colorscheme.lua`

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/colorscheme.lua`

- [ ] **Step 1: Add everforest to the manifest**

In `lua/config/pack.lua`, replace the empty `vim.pack.add({})` block with:

```lua
vim.pack.add({
  -- Colorscheme
  { src = 'https://github.com/neanias/everforest-nvim' },
})
```

- [ ] **Step 2: Create the colorscheme module**

```lua
-- ============================================================================
-- Colorscheme — `everforest`. Set after vim.pack.add has run so the plugin
-- is on runtimepath. We override `LazyVim`'s old approach (set as opt) since
-- there is no LazyVim anymore — direct setup() + colorscheme call.
-- ============================================================================

local ok, everforest = pcall(require, 'everforest')
if not ok then return end

everforest.setup({
  background = 'medium',     -- soft | medium | hard
  italics = true,
  ui_contrast = 'low',
  diagnostic_text_highlight = true,
  diagnostic_line_highlight = false,
  spell_foreground = false,
})

-- Apply. Wrap in pcall so a missing colorscheme doesn't abort startup
-- (e.g. on first run before vim.pack has finished cloning).
pcall(vim.cmd.colorscheme, 'everforest')
```

- [ ] **Step 3: First-run install + verify**

```bash
nvk --headless +'echo "background = " .. (vim.o.background or "?")' +qa 2>&1
```

First run: vim.pack clones everforest (you'll see clone output); subsequent runs are quiet.

Then verify the scheme actually applies:

```bash
nvk --headless +'echo g:colors_name' +qa 2>&1
```

Expected: `everforest`.

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/colorscheme.lua
git commit -m "feat(plugins): add everforest colorscheme

First plugin under vim.pack. Verifies the install path works end-to-end.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 3 — Treesitter

### Task 10: Bring up `tree-sitter-manager.nvim` + textobjects + context

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/treesitter.lua`

- [ ] **Step 1: Read tree-sitter-manager.nvim's README**

Open https://github.com/romus204/tree-sitter-manager.nvim in a browser and confirm:
- The exact module name passed to `require()` (assumed: `tree-sitter-manager`).
- Setup function signature (assumed: `setup({ ensure_installed, auto_install })`).
- Public commands (assumed: `:TSManager`, `:TSManagerUpdate`, `:TSManagerInstall`).

If the names differ, adjust the code in subsequent steps before committing. **This is the only research step in the plan; do not skip it.**

- [ ] **Step 2: Add to manifest**

Append to the `vim.pack.add({...})` table in `lua/config/pack.lua`:

```lua
  -- Treesitter
  { src = 'https://github.com/romus204/tree-sitter-manager.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },
```

- [ ] **Step 3: Create `<repo>/lua/plugins/treesitter.lua`**

```lua
-- ============================================================================
-- Treesitter. We use tree-sitter-manager.nvim (active fork) instead of the
-- archived nvim-treesitter mainline.
--
-- Highlight is started per-buffer via FileType autocmd: vim.treesitter.start
-- locates the parser and attaches it. Textobjects + context still ship as
-- separate (active) plugins on top.
-- ============================================================================

local lang = require('config.lang')

local ok, tsm = pcall(require, 'tree-sitter-manager')
if ok then
  tsm.setup({
    ensure_installed = lang.parsers,  -- empty until lang/*.lua modules land
    auto_install = true,
  })
end

-- Start treesitter highlighting on every filetype whose parser is installed.
-- pcall both ends so an uninstalled parser is silent, not noisy.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('config_treesitter_start', { clear = true }),
  callback = function(ev)
    pcall(vim.treesitter.start, ev.buf)
  end,
})

-- Textobjects: af/if for function outer/inner, ac/ic for class.
local ok_to, to = pcall(require, 'nvim-treesitter-textobjects')
if ok_to then
  to.setup({
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
  })
end

-- Context: sticky header showing the current function/class. 3 lines max
-- so it doesn't dominate the screen.
local ok_ctx, ctx = pcall(require, 'treesitter-context')
if ok_ctx then ctx.setup({ max_lines = 3 }) end

-- ---------- Treesitter manager keymaps ----------------------------------------
-- Adjust right-hand sides to match the actual API discovered in Step 1.
local map = vim.keymap.set
map('n', '<leader>lt',  '<cmd>TSManager<cr>',         { desc = 'Treesitter: Manager UI' })
map('n', '<leader>ltu', '<cmd>TSManagerUpdate<cr>',   { desc = 'Treesitter: Update parsers' })
map('n', '<leader>lti', '<cmd>TSManagerInstall<cr>',  { desc = 'Treesitter: Install parser' })
```

- [ ] **Step 4: Verify install + filetype autocmd**

```bash
nvk --headless lua/config/options.lua +'lua print(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil)' +qa 2>&1
```

First run installs the plugins. Expected after install: prints `true` (highlighter is attached). If `false`, check that the `lua` parser exists — it ships with Neovim, so it should be available even before `lang/lua.lua` lands.

- [ ] **Step 5: Commit**

```bash
git add lua/config/pack.lua lua/plugins/treesitter.lua
git commit -m "feat(plugins): wire tree-sitter-manager + textobjects + context

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 4 — LSP infrastructure (Lua as the bootstrap language)

### Task 11: Add Mason + lspconfig + lazydev; first language module (`lua`)

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/lsp.lua`
- Create: `<repo>/lua/plugins/lang/lua.lua`

- [ ] **Step 1: Add to manifest**

Append to `vim.pack.add({...})` in `lua/config/pack.lua`:

```lua
  -- LSP infrastructure
  { src = 'https://github.com/williamboman/mason.nvim' },
  { src = 'https://github.com/williamboman/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/folke/lazydev.nvim' },
```

- [ ] **Step 2: Create the first language module (`lang/lua.lua`)**

```lua
-- ============================================================================
-- Lua language module. We edit Lua here (this very repo) so this lands first.
-- Note: lazydev.nvim teaches lua_ls about Neovim's runtime API; configured
-- in plugins/lsp.lua, not here.
-- ============================================================================

return {
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
          diagnostics = { globals = { 'vim' } },
        },
      },
    },
  },
  formatters_by_ft = { lua = { 'stylua' } },
  parsers          = { 'lua', 'luadoc', 'vim', 'vimdoc', 'query' },
  mason_tools      = { 'lua-language-server', 'stylua' },
}
```

- [ ] **Step 3: Create `lua/plugins/lsp.lua`**

```lua
-- ============================================================================
-- LSP wiring.
--
-- Pipeline:
--   lang/<name>.lua → config.lang aggregator → here.
--
-- We use the Neovim 0.11+ `vim.lsp.config(name, opts)` API to register each
-- server. mason-lspconfig's `automatic_enable` then starts the right server
-- when a buffer of the matching filetype opens.
--
-- LSP-specific keymaps live in the LspAttach callback (buffer-scoped) so they
-- don't pollute non-LSP buffers.
-- ============================================================================

local lang = require('config.lang')

-- Mason: installs LSP servers, formatters, linters, DAPs as binaries under
-- <data>/mason/. mason-tool-installer makes the per-language `mason_tools`
-- list declarative — drift between the manifest and disk is auto-corrected.
require('mason').setup()
require('mason-tool-installer').setup({
  ensure_installed = lang.mason_tools,
  run_on_start = true,
})

-- lazydev: makes lua_ls aware of Neovim's runtime + plugin Lua so completion
-- and goto-definition work when editing config like this file.
local ok_lazydev, lazydev = pcall(require, 'lazydev')
if ok_lazydev then
  lazydev.setup({
    library = {
      { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      'lazy.nvim',
    },
  })
end

-- Register every server's config blob.
for name, opts in pairs(lang.servers) do
  vim.lsp.config(name, opts)
end

-- mason-lspconfig wires Mason-installed servers to lspconfig + auto-enables.
require('mason-lspconfig').setup({
  ensure_installed = vim.tbl_keys(lang.servers),
  automatic_enable = true,
})

-- ---------- LspAttach: buffer-local keymaps when a server attaches -----------
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('config_lsp_attach', { clear = true }),
  callback = function(ev)
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', vim.lsp.buf.definition,      'Goto Definition')
    map('gr', vim.lsp.buf.references,      'References')
    map('gI', vim.lsp.buf.implementation,  'Implementation')
    map('gy', vim.lsp.buf.type_definition, 'Type Definition')
    map('gD', vim.lsp.buf.declaration,     'Declaration')
    map('K',  vim.lsp.buf.hover,           'Hover')
    map('gK', vim.lsp.buf.signature_help,  'Signature Help')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    -- <leader>cr is owned by inc-rename (set in plugins/coding.lua).
    map('<leader>cR', vim.lsp.buf.rename, 'LSP Rename')
    map('<leader>cf', function()
      require('conform').format({ async = true, lsp_format = 'fallback' })
    end, 'Format')
    map('<leader>cl', '<cmd>checkhealth vim.lsp<cr>', 'LSP Info')
  end,
})
```

- [ ] **Step 4: First-run install (Mason will fetch lua-language-server + stylua)**

```bash
nvk --headless +'lua require("mason-tool-installer").run_on_start()' +qa 2>&1
# Then open a Lua file interactively to confirm the server attaches:
nvk lua/config/options.lua
# In nvim: run `:LspInfo` or `<leader>cl` and confirm `lua_ls` is attached.
# Then `:q`.
```

Expected: Mason UI background-installs `lua-language-server` and `stylua`. After install, opening a Lua file produces an attached `lua_ls` server visible in `:LspInfo`.

- [ ] **Step 5: Commit**

```bash
git add lua/config/pack.lua lua/plugins/lsp.lua lua/plugins/lang/lua.lua
git commit -m "feat(plugins): add LSP infra (mason, lspconfig, lazydev) and lua lang module

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 5 — Coding: conform, nvim-lint, blink.cmp, inc-rename

### Task 12: `conform.nvim` + `nvim-lint`

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/coding.lua`

- [ ] **Step 1: Add to manifest**

```lua
  -- Coding
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-lint' },
```

- [ ] **Step 2: Create `lua/plugins/coding.lua` with conform + lint only (blink/inc-rename in next tasks)**

```lua
-- ============================================================================
-- Coding: format, lint, complete, rename. Each section is independent — if
-- one fails to load, the others still work.
-- ============================================================================

local lang = require('config.lang')

-- ---------- conform.nvim — formatters by filetype -----------------------------
-- format_on_save respects two opt-out flags so <leader>uf / <leader>uF can
-- toggle per buffer or globally without deleting the autocmd.
local ok_conform, conform = pcall(require, 'conform')
if ok_conform then
  conform.setup({
    formatters_by_ft = lang.formatters_by_ft,
    format_on_save = function(buf)
      if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
      return { lsp_format = 'fallback', timeout_ms = 2000 }
    end,
  })
end

-- ---------- nvim-lint — linters by filetype -----------------------------------
local ok_lint, lint = pcall(require, 'lint')
if ok_lint then
  lint.linters_by_ft = lang.linters_by_ft
  vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
    group = vim.api.nvim_create_augroup('config_lint', { clear = true }),
    callback = function() lint.try_lint() end,
  })
end
```

- [ ] **Step 3: Verify formatting on save**

```bash
nvk lua/config/options.lua
# In nvim: insert a misformatted line, save with :w, watch stylua reformat.
# Then :q.
```

Expected: `:w` triggers stylua; the buffer reformats.

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/coding.lua
git commit -m "feat(plugins): add conform + nvim-lint with format-on-save toggle

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 13: `blink.cmp` (with super-tab + snippet-aware preselect)

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Modify: `<repo>/lua/plugins/coding.lua`

- [ ] **Step 1: Add to manifest with version pin**

```lua
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
```

- [ ] **Step 2: Append blink setup to `coding.lua`**

```lua
-- ---------- blink.cmp — completion engine -------------------------------------
-- super-tab preset: <Tab> accepts the suggestion or jumps to the next snippet
-- field. The preselect callback suppresses preselect *while a snippet is
-- expanding* so <Tab> advances the snippet field instead of accepting an
-- unrelated completion item.
local ok_blink, blink = pcall(require, 'blink.cmp')
if ok_blink then
  blink.setup({
    keymap = { preset = 'super-tab' },
    completion = {
      list = {
        selection = {
          preselect = function(ctx)
            return not require('blink.cmp').snippet_active({ direction = 1 })
          end,
        },
      },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
  })
end
```

- [ ] **Step 3: Verify completion**

```bash
nvk lua/config/options.lua
# In insert mode, type `vim.opt.` and confirm a completion menu appears with
# LSP-sourced suggestions. <Tab> should accept the highlighted item.
```

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/coding.lua
git commit -m "feat(plugins): wire blink.cmp with super-tab and snippet-aware preselect

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 14: `inc-rename`

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Modify: `<repo>/lua/plugins/coding.lua`
- Modify: `<repo>/lua/config/keymaps.lua`

- [ ] **Step 1: Add to manifest**

```lua
  { src = 'https://github.com/smjonas/inc-rename.nvim' },
```

- [ ] **Step 2: Append inc-rename setup to `coding.lua`**

```lua
-- ---------- inc-rename — live-preview LSP rename ------------------------------
local ok_inc, inc = pcall(require, 'inc_rename')
if ok_inc then inc.setup() end
```

- [ ] **Step 3: Add the `<leader>cr` keymap to `lua/config/keymaps.lua`** (under a new "Rename" section):

```lua
-- ---------- Rename ------------------------------------------------------------
-- inc-rename: live-preview LSP rename of the symbol under cursor.
-- LSP rename without preview lives at <leader>cR (set in plugins/lsp.lua).
map('n', '<leader>cr', function()
  return ':IncRename ' .. vim.fn.expand('<cword>')
end, { expr = true, desc = 'Rename (inc-rename)' })
```

- [ ] **Step 4: Verify**

```bash
nvk lua/config/options.lua
# Place cursor on a local variable name, hit <leader>cr, type a new name, see
# every occurrence preview update live. Confirm with <CR>.
```

- [ ] **Step 5: Commit**

```bash
git add lua/config/pack.lua lua/plugins/coding.lua lua/config/keymaps.lua
git commit -m "feat(plugins): add inc-rename with leader-cr live preview

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 6 — Picker & explorer (Snacks)

### Task 15: `snacks.nvim` (picker, explorer, notifier, dashboard, bigfile)

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/picker.lua`

- [ ] **Step 1: Add to manifest**

```lua
  -- UI / picker / explorer / notifier (Snacks bundle)
  { src = 'https://github.com/folke/snacks.nvim' },
```

- [ ] **Step 2: Create `<repo>/lua/plugins/picker.lua`**

```lua
-- ============================================================================
-- Snacks: a bundle of small UI utilities. We enable picker, explorer,
-- notifier, dashboard, bigfile, and scope. Each is a sub-module of one plugin.
--
-- Picker = telescope replacement. Explorer = neo-tree replacement.
-- Both share Snacks' input UI so muscle memory transfers between them.
-- ============================================================================

local ok, snacks = pcall(require, 'snacks')
if not ok then return end

snacks.setup({
  picker    = { enabled = true },
  explorer  = { enabled = true },
  notifier  = { enabled = true, timeout = 3000 },
  dashboard = { enabled = true },
  bigfile   = { enabled = true },
  scope     = { enabled = true },
  input     = { enabled = true },
  scroll    = { enabled = false },  -- turn on if you want smooth scrolling
})

local map = vim.keymap.set

-- ---------- File pickers (<leader>f*) -----------------------------------------
map('n', '<leader>ff', function() Snacks.picker.files() end,                       { desc = 'Find Files' })
map('n', '<leader>fF', function() Snacks.picker.files({ cwd = vim.uv.cwd() }) end, { desc = 'Find Files (cwd)' })
map('n', '<leader>fr', function() Snacks.picker.recent() end,                      { desc = 'Recent Files' })
map('n', '<leader>fb', function() Snacks.picker.buffers() end,                     { desc = 'Buffers' })
map('n', '<leader>fc', function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end, { desc = 'Config Files' })
map('n', '<leader>fp', function() Snacks.picker.projects() end,                    { desc = 'Projects' })

-- ---------- Search pickers (<leader>s*) ---------------------------------------
map('n', '<leader>sg', function() Snacks.picker.grep() end,             { desc = 'Live Grep' })
map('n', '<leader>sw', function() Snacks.picker.grep_word() end,        { desc = 'Grep Word' })
map('n', '<leader>sh', function() Snacks.picker.help() end,             { desc = 'Help' })
map('n', '<leader>sk', function() Snacks.picker.keymaps() end,          { desc = 'Keymaps' })
map('n', '<leader>sd', function() Snacks.picker.diagnostics() end,      { desc = 'Diagnostics (workspace)' })
map('n', '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, { desc = 'Diagnostics (buffer)' })
map('n', '<leader>sr', function() Snacks.picker.resume() end,           { desc = 'Resume Picker' })
map('n', '<leader>ss', function() Snacks.picker.lsp_symbols() end,      { desc = 'Document Symbols' })
map('n', '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, { desc = 'Workspace Symbols' })
map('n', '<leader>:',  function() Snacks.picker.command_history() end,  { desc = 'Command History' })

-- ---------- Explorer (<leader>e) ----------------------------------------------
map('n', '<leader>e', function() Snacks.explorer() end,                              { desc = 'Explorer (root)' })
map('n', '<leader>E', function() Snacks.explorer({ cwd = vim.uv.cwd() }) end,        { desc = 'Explorer (cwd)' })
```

- [ ] **Step 3: Verify**

```bash
nvk
# In nvim: <leader>ff (picker), <leader>e (explorer), <leader>sg (grep).
# Confirm each opens the expected UI. :q.
```

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/picker.lua
git commit -m "feat(plugins): add Snacks (picker, explorer, notifier, dashboard, bigfile)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 7 — UI extras (lualine, icons, todo-comments, indent-blankline)

### Task 16: UI bundle

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/ui.lua`

- [ ] **Step 1: Add to manifest**

```lua
  -- UI extras
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/echasnovski/mini.icons' },
  { src = 'https://github.com/folke/todo-comments.nvim' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },
```

- [ ] **Step 2: Create `<repo>/lua/plugins/ui.lua`**

```lua
-- ============================================================================
-- UI: statusline (lualine), icons (mini.icons), todo highlights, indent guides.
-- ============================================================================

-- mini.icons: provider for filetype/file/extension icons. Lualine and snacks
-- read this provider via mini.icons.mock_nvim_web_devicons() so plugins that
-- expect the older nvim-web-devicons API still work.
local ok_icons, icons = pcall(require, 'mini.icons')
if ok_icons then
  icons.setup()
  icons.mock_nvim_web_devicons()
end

-- lualine: minimal statusline, everforest theme picks up colors automatically.
local ok_lualine, lualine = pcall(require, 'lualine')
if ok_lualine then
  lualine.setup({
    options = {
      theme = 'everforest',
      section_separators = '',
      component_separators = '|',
      globalstatus = true,        -- one statusline at the bottom of all splits
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { { 'filename', path = 1 } },          -- relative path
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
  })
end

-- todo-comments: highlight TODO/FIXME/HACK/NOTE/WARN/PERF in comments and
-- exposes a picker (Snacks integration via :TodoTelescope is replaced — we
-- bind <leader>st to call Snacks.picker.todos when available).
local ok_todo, todo = pcall(require, 'todo-comments')
if ok_todo then
  todo.setup()
  vim.keymap.set('n', '<leader>st', function()
    if Snacks and Snacks.picker and Snacks.picker.todos then
      Snacks.picker.todos()
    else
      vim.cmd('TodoQuickFix')
    end
  end, { desc = 'TODOs' })
end

-- indent-blankline: subtle vertical guides at indent levels.
local ok_ibl, ibl = pcall(require, 'ibl')
if ok_ibl then
  ibl.setup({
    indent = { char = '│' },
    scope  = { enabled = false },  -- Snacks.scope already does this
  })
end
```

- [ ] **Step 3: Verify**

```bash
nvk
# Confirm: statusline at bottom shows mode/branch/file/etc., file icons render
# in the explorer, indent guides are visible. :q.
```

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/ui.lua
git commit -m "feat(plugins): add UI bundle (lualine, mini.icons, todo, indent-blankline)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 8 — Editor (mini.*, smart-splits, grapple, dial, yanky)

### Task 17: Editor bundle

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/editor.lua`

- [ ] **Step 1: Add to manifest**

```lua
  -- Editor
  { src = 'https://github.com/echasnovski/mini.surround' },
  { src = 'https://github.com/echasnovski/mini.ai' },
  { src = 'https://github.com/echasnovski/mini.hipatterns' },
  { src = 'https://github.com/monaqa/dial.nvim' },
  { src = 'https://github.com/gbprod/yanky.nvim' },
  { src = 'https://github.com/mrjones2014/smart-splits.nvim' },
  { src = 'https://github.com/cbochs/grapple.nvim' },
```

- [ ] **Step 2: Create `<repo>/lua/plugins/editor.lua`**

```lua
-- ============================================================================
-- Editor enhancements. Each plugin is independent; one failing doesn't break
-- the others. Custom keymaps live here, near the plugin they drive.
-- ============================================================================

local map = vim.keymap.set

-- ---------- mini.surround: ysiw" / ds( / cs'" --------------------------------
local ok_surround, surround = pcall(require, 'mini.surround')
if ok_surround then surround.setup() end

-- ---------- mini.ai: better text objects (af, ai, etc.) -----------------------
local ok_ai, ai = pcall(require, 'mini.ai')
if ok_ai then ai.setup({ n_lines = 500 }) end

-- ---------- mini.hipatterns: highlight #FF0066 etc. inline --------------------
local ok_hi, hi = pcall(require, 'mini.hipatterns')
if ok_hi then
  hi.setup({
    highlighters = {
      hex_color = hi.gen_highlighter.hex_color(),
    },
  })
end

-- ---------- dial: <C-a> / <C-x> on dates, booleans, hex, etc. -----------------
local ok_dial = pcall(require, 'dial.config')
if ok_dial then
  -- defaults are sensible; no custom group registration needed.
  map('n', '<C-a>', '<Plug>(dial-increment)')
  map('n', '<C-x>', '<Plug>(dial-decrement)')
  map('v', '<C-a>', '<Plug>(dial-increment)')
  map('v', '<C-x>', '<Plug>(dial-decrement)')
end

-- ---------- yanky: persistent yank ring + paste navigation --------------------
local ok_yanky, yanky = pcall(require, 'yanky')
if ok_yanky then
  yanky.setup({
    ring = { storage = 'shada' },  -- survives nvim restarts via shada file
  })
  map({ 'n', 'x' }, 'p',  '<Plug>(YankyPutAfter)')
  map({ 'n', 'x' }, 'P',  '<Plug>(YankyPutBefore)')
  map('n',          '<C-n>', '<Plug>(YankyCycleForward)')
  map('n',          '<C-p>', '<Plug>(YankyCycleBackward)')
end

-- ---------- smart-splits: <C-hjkl> across nvim splits AND Zellij panes --------
local ok_smart, smart = pcall(require, 'smart-splits')
if ok_smart then
  smart.setup({
    at_edge = 'wrap',
    -- multiplexer is auto-detected (Zellij in our case).
  })
  map('n', '<C-h>', smart.move_cursor_left,  { desc = 'Window/pane left' })
  map('n', '<C-j>', smart.move_cursor_down,  { desc = 'Window/pane down' })
  map('n', '<C-k>', smart.move_cursor_up,    { desc = 'Window/pane up' })
  map('n', '<C-l>', smart.move_cursor_right, { desc = 'Window/pane right' })
  map('n', '<A-h>', smart.resize_left,       { desc = 'Resize left' })
  map('n', '<A-j>', smart.resize_down,       { desc = 'Resize down' })
  map('n', '<A-k>', smart.resize_up,         { desc = 'Resize up' })
  map('n', '<A-l>', smart.resize_right,      { desc = 'Resize right' })
end

-- ---------- grapple: persistent file tags for the current working set --------
local ok_grapple, grapple = pcall(require, 'grapple')
if ok_grapple then
  -- defaults are good; no setup() call required.
  map('n', '<leader>m', function() grapple.toggle() end,            { desc = 'Toggle File Tag' })
  map('n', '<leader>M', function() grapple.toggle_tags() end,        { desc = 'Open File Tags' })
  map('n', ']m',        function() grapple.cycle_tags('next') end,   { desc = 'Next File Tag' })
  map('n', '[m',        function() grapple.cycle_tags('prev') end,   { desc = 'Prev File Tag' })
  for i = 1, 4 do
    map('n', '<leader>' .. i, function() grapple.select({ index = i }) end, { desc = 'Jump to Tag ' .. i })
  end
end

-- ---------- macOS clipboard yank in visual ------------------------------------
map('v', '<D-c>', '"+y', { noremap = true, silent = true, desc = 'Copy to system clipboard' })
```

- [ ] **Step 3: Verify**

```bash
nvk
# In nvim: ysiw" wraps a word in quotes (mini.surround), <C-h>/<C-l> jumps
# between splits, <leader>m tags the current file (Grapple), <C-a> on a number
# increments it. :q.
```

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/editor.lua
git commit -m "feat(plugins): add editor bundle (mini, dial, yanky, smart-splits, grapple)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 9 — Git (gitsigns + diffview)

### Task 18: Git bundle

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/git.lua`

- [ ] **Step 1: Add to manifest**

```lua
  -- Git
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/sindrets/diffview.nvim' },
```

- [ ] **Step 2: Create `<repo>/lua/plugins/git.lua`**

```lua
-- ============================================================================
-- Git: gutter signs (gitsigns) + in-editor diff/history (diffview).
-- Lazygit lives outside nvim; <leader>gg is wired in plugins/picker.lua via
-- Snacks (it shells out to lazygit; install it separately).
-- ============================================================================

local map = vim.keymap.set

-- ---------- gitsigns: gutter +/-/~, stage/reset hunks, blame ------------------
local ok_gs, gs = pcall(require, 'gitsigns')
if ok_gs then
  gs.setup({
    on_attach = function(buf)
      local function bmap(lhs, rhs, desc) map('n', lhs, rhs, { buffer = buf, desc = desc }) end
      bmap(']c', function() gs.nav_hunk('next') end, 'Next Hunk')
      bmap('[c', function() gs.nav_hunk('prev') end, 'Prev Hunk')
      bmap('<leader>hs', gs.stage_hunk,    'Stage Hunk')
      bmap('<leader>hr', gs.reset_hunk,    'Reset Hunk')
      bmap('<leader>hp', gs.preview_hunk,  'Preview Hunk')
      bmap('<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame Line')
    end,
  })
end

-- ---------- diffview: in-editor diff + file history ---------------------------
local ok_dv, dv = pcall(require, 'diffview')
if ok_dv then dv.setup() end

-- ---------- Lazygit + git pickers (Snacks-driven) -----------------------------
map('n', '<leader>gg', function() Snacks.lazygit({ cwd = vim.fs.root(0, '.git') }) end, { desc = 'Lazygit (root)' })
map('n', '<leader>gG', function() Snacks.lazygit() end,                                { desc = 'Lazygit (cwd)' })
map('n', '<leader>gb', function() Snacks.picker.git_log_line() end,                    { desc = 'Git Blame Line' })
map('n', '<leader>gf', function() Snacks.picker.git_log_file() end,                    { desc = 'Git File History' })
map('n', '<leader>gl', function() Snacks.picker.git_log({ cwd = vim.fs.root(0, '.git') }) end, { desc = 'Git Log (root)' })
map('n', '<leader>gL', function() Snacks.picker.git_log() end,                         { desc = 'Git Log (cwd)' })
map('n', '<leader>gB', function() Snacks.gitbrowse() end,                              { desc = 'Git Browse (open)' })
map('n', '<leader>gY', function() Snacks.gitbrowse({ open = function(url) vim.fn.setreg('+', url) end }) end, { desc = 'Git Browse (yank URL)' })

-- ---------- Diffview keymaps (carry over verbatim) ----------------------------
map('n', '<leader>gvo', '<cmd>DiffviewOpen<cr>',         { desc = 'Diffview Open' })
map('n', '<leader>gvc', '<cmd>DiffviewClose<cr>',        { desc = 'Diffview Close' })
map('n', '<leader>gvf', '<cmd>DiffviewFileHistory %<cr>',{ desc = 'Diffview File History' })
map('n', '<leader>gvh', '<cmd>DiffviewFileHistory<cr>',  { desc = 'Diffview Repo History' })
```

- [ ] **Step 3: Verify**

```bash
nvk lua/config/options.lua
# Confirm: gitsigns shows +/- in gutter for any unstaged changes,
# <leader>gg opens lazygit, <leader>gvo opens Diffview. :q.
```

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/git.lua
git commit -m "feat(plugins): add gitsigns + diffview + lazygit/git pickers

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 10 — AI (Copilot)

### Task 19: Copilot + CopilotChat

**Files:**
- Modify: `<repo>/lua/config/pack.lua`
- Create: `<repo>/lua/plugins/ai.lua`

- [ ] **Step 1: Add to manifest**

```lua
  -- AI
  { src = 'https://github.com/zbirenbaum/copilot.lua' },
  { src = 'https://github.com/CopilotC-Nvim/CopilotChat.nvim' },
```

- [ ] **Step 2: Create `<repo>/lua/plugins/ai.lua`**

```lua
-- ============================================================================
-- AI: GitHub Copilot inline + chat. Auth is handled by `:Copilot auth` on
-- first run (browser flow). Token persists in <data>/github-copilot/.
-- ============================================================================

local map = vim.keymap.set

-- ---------- copilot.lua: inline ghost-text suggestions ------------------------
-- We disable copilot's built-in panel/suggestion keymaps because blink.cmp
-- handles completion. Copilot only provides ghost text on idle.
local ok_cop, cop = pcall(require, 'copilot')
if ok_cop then
  cop.setup({
    suggestion = { enabled = true, auto_trigger = true, keymap = { accept = '<M-l>' } },
    panel      = { enabled = false },
    filetypes  = {
      markdown = true,
      gitcommit = true,
      ['*'] = true,
    },
  })
end

-- ---------- CopilotChat: a chat buffer using Copilot as the model ------------
local ok_chat, chat = pcall(require, 'CopilotChat')
if ok_chat then
  chat.setup({
    model = 'gpt-4o',
    debug = false,
  })
  map({ 'n', 'v' }, '<leader>cc', '<cmd>CopilotChat<cr>',          { desc = 'Copilot Chat' })
  map({ 'n', 'v' }, '<leader>ce', '<cmd>CopilotChatExplain<cr>',   { desc = 'Copilot Explain' })
  map({ 'n', 'v' }, '<leader>cq', '<cmd>CopilotChatQuickChat<cr>', { desc = 'Copilot Quick Chat' })
end
```

- [ ] **Step 3: First-run auth + verify**

```bash
nvk
# In nvim: :Copilot auth — opens a browser, paste device code from nvim
# message into the GitHub page. Once authed, in any code buffer you should
# see grey ghost-text suggestions on idle. :q.
```

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua lua/plugins/ai.lua
git commit -m "feat(plugins): add copilot.lua + CopilotChat

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 11 — Languages (14 modules, batched)

Each language module follows the contract in `lua/config/lang.lua`. Per-language Mason tools install on next nvk launch via `mason-tool-installer`. Parsers install via `tree-sitter-manager`.

### Task 20: Markup & data (`json`, `yaml`, `toml`, `markdown`)

**Files:**
- Create: `<repo>/lua/plugins/lang/json.lua`
- Create: `<repo>/lua/plugins/lang/yaml.lua`
- Create: `<repo>/lua/plugins/lang/toml.lua`
- Create: `<repo>/lua/plugins/lang/markdown.lua`

- [ ] **Step 1: `json.lua`**

```lua
return {
  servers = { jsonls = {} },
  formatters_by_ft = { json = { 'prettierd', 'prettier', stop_after_first = true } },
  parsers     = { 'json', 'jsonc', 'json5' },
  mason_tools = { 'json-lsp', 'prettierd' },
}
```

- [ ] **Step 2: `yaml.lua`**

```lua
return {
  servers = { yamlls = { settings = { yaml = { keyOrdering = false } } } },
  formatters_by_ft = { yaml = { 'prettierd', 'prettier', stop_after_first = true } },
  parsers     = { 'yaml' },
  mason_tools = { 'yaml-language-server' },
}
```

- [ ] **Step 3: `toml.lua`**

```lua
return {
  servers     = { taplo = {} },
  formatters_by_ft = { toml = { 'taplo' } },
  parsers     = { 'toml' },
  mason_tools = { 'taplo' },
}
```

- [ ] **Step 4: `markdown.lua`**

```lua
return {
  servers = { marksman = {} },
  formatters_by_ft = { markdown = { 'prettierd', 'prettier', stop_after_first = true } },
  linters_by_ft = { markdown = { 'markdownlint' } },
  parsers     = { 'markdown', 'markdown_inline' },
  mason_tools = { 'marksman', 'markdownlint' },
}
```

- [ ] **Step 5: Restart nvk to install + verify**

```bash
nvk --headless +'lua require("mason-tool-installer").run_on_start()' +qa 2>&1
nvk README.md
# Confirm marksman attaches (:LspInfo). :q.
```

- [ ] **Step 6: Commit**

```bash
git add lua/plugins/lang/{json,yaml,toml,markdown}.lua
git commit -m "feat(lang): add markup/data languages (json, yaml, toml, markdown)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 21: Compiled (`go`, `rust`, `cmake`)

**Files:**
- Create: `<repo>/lua/plugins/lang/go.lua`
- Create: `<repo>/lua/plugins/lang/rust.lua`
- Create: `<repo>/lua/plugins/lang/cmake.lua`

- [ ] **Step 1: `go.lua`**

```lua
return {
  servers = {
    gopls = {
      settings = {
        gopls = {
          gofumpt = true,
          analyses = { unusedparams = true, shadow = true },
          staticcheck = true,
          hints = { parameterNames = true, assignVariableTypes = true },
        },
      },
    },
  },
  formatters_by_ft = { go = { 'gofumpt', 'goimports' } },
  linters_by_ft = { go = { 'golangcilint' } },
  parsers     = { 'go', 'gomod', 'gosum', 'gowork' },
  mason_tools = { 'gopls', 'gofumpt', 'goimports', 'golangci-lint' },
}
```

- [ ] **Step 2: `rust.lua`**

```lua
return {
  servers = {
    rust_analyzer = {
      settings = {
        ['rust-analyzer'] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = 'clippy' },
          procMacro = { enable = true },
        },
      },
    },
  },
  parsers     = { 'rust', 'ron' },
  mason_tools = { 'rust-analyzer' },
  -- Note: rustfmt + clippy come with the rust toolchain; install via rustup,
  -- not Mason. conform.nvim will pick them up if they're on PATH.
}
```

- [ ] **Step 3: `cmake.lua`**

```lua
return {
  servers     = { cmake = {} },
  parsers     = { 'cmake' },
  mason_tools = { 'cmake-language-server' },
}
```

- [ ] **Step 4: Restart + verify**

```bash
nvk --headless +'lua require("mason-tool-installer").run_on_start()' +qa 2>&1
```

- [ ] **Step 5: Commit**

```bash
git add lua/plugins/lang/{go,rust,cmake}.lua
git commit -m "feat(lang): add compiled languages (go, rust, cmake)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 22: Scripting (`python`, `ruby`, `typescript`)

**Files:**
- Create: `<repo>/lua/plugins/lang/python.lua`
- Create: `<repo>/lua/plugins/lang/ruby.lua`
- Create: `<repo>/lua/plugins/lang/typescript.lua`

- [ ] **Step 1: `python.lua`**

```lua
return {
  servers = {
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = 'basic',
            diagnosticMode = 'workspace',
            useLibraryCodeForTypes = true,
          },
        },
      },
    },
  },
  formatters_by_ft = { python = { 'ruff_format', 'ruff_organize_imports' } },
  linters_by_ft = { python = { 'ruff' } },
  parsers     = { 'python' },
  mason_tools = { 'pyright', 'ruff' },
}
```

- [ ] **Step 2: `ruby.lua`**

```lua
return {
  servers = { ruby_lsp = {} },
  formatters_by_ft = { ruby = { 'rubocop' } },
  linters_by_ft = { ruby = { 'rubocop' } },
  parsers     = { 'ruby' },
  mason_tools = { 'ruby-lsp', 'rubocop' },
}
```

- [ ] **Step 3: `typescript.lua`**

```lua
return {
  servers = {
    vtsls = {
      settings = {
        typescript = { inlayHints = { parameterNames = { enabled = 'all' } } },
        javascript = { inlayHints = { parameterNames = { enabled = 'all' } } },
      },
    },
  },
  formatters_by_ft = {
    javascript = { 'prettierd', 'prettier', stop_after_first = true },
    typescript = { 'prettierd', 'prettier', stop_after_first = true },
    javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
    typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
  },
  linters_by_ft = {
    javascript = { 'eslint_d' },
    typescript = { 'eslint_d' },
  },
  parsers     = { 'javascript', 'typescript', 'tsx', 'jsdoc' },
  mason_tools = { 'vtsls', 'prettierd', 'eslint_d' },
}
```

- [ ] **Step 4: Restart + verify**

```bash
nvk --headless +'lua require("mason-tool-installer").run_on_start()' +qa 2>&1
```

- [ ] **Step 5: Commit**

```bash
git add lua/plugins/lang/{python,ruby,typescript}.lua
git commit -m "feat(lang): add scripting languages (python, ruby, typescript)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 23: DevOps (`docker`, `terraform`, `git`, `sql`)

**Files:**
- Create: `<repo>/lua/plugins/lang/docker.lua`
- Create: `<repo>/lua/plugins/lang/terraform.lua`
- Create: `<repo>/lua/plugins/lang/git.lua`
- Create: `<repo>/lua/plugins/lang/sql.lua`

- [ ] **Step 1: `docker.lua`**

```lua
return {
  servers = {
    dockerls = {},
    docker_compose_language_service = {},
  },
  parsers     = { 'dockerfile' },
  mason_tools = { 'dockerfile-language-server', 'docker-compose-language-service' },
}
```

- [ ] **Step 2: `terraform.lua`**

```lua
return {
  servers = { terraformls = {} },
  formatters_by_ft = { terraform = { 'terraform_fmt' }, hcl = { 'terraform_fmt' } },
  parsers     = { 'terraform', 'hcl' },
  mason_tools = { 'terraform-ls' },
}
```

- [ ] **Step 3: `git.lua`** (note: filename collides with `lua/plugins/git.lua` — that's a different module under `lang/`, fine)

```lua
-- Filetypes: gitcommit, gitignore, gitattributes, gitrebase. No LSP server,
-- but parsers + a few formatters keep the experience consistent.
return {
  parsers = { 'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore' },
}
```

- [ ] **Step 4: `sql.lua`**

```lua
return {
  servers = { sqlls = {} },
  formatters_by_ft = { sql = { 'sql_formatter' } },
  parsers     = { 'sql' },
  mason_tools = { 'sqlls', 'sql-formatter' },
}
```

- [ ] **Step 5: Restart + verify**

```bash
nvk --headless +'lua require("mason-tool-installer").run_on_start()' +qa 2>&1
```

- [ ] **Step 6: Commit**

```bash
git add lua/plugins/lang/{docker,terraform,git,sql}.lua
git commit -m "feat(lang): add devops languages (docker, terraform, git, sql)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 12 — Plugin manager UI polish

### Task 24: Implement `:Pack` scratch UI and `:PackClean`

**Files:**
- Modify: `<repo>/lua/config/pack.lua`

- [ ] **Step 1: Replace the placeholder `:Pack` and `:PackClean` implementations**

In `lua/config/pack.lua`, replace the existing `:Pack` and `:PackClean` user-command definitions with:

```lua
-- Helper: read the manifest's set of plugin names by re-reading vim.pack.get()
-- after vim.pack.add has run. (vim.pack tracks every plugin we've registered.)
local function manifest_names()
  local names = {}
  for _, p in ipairs(vim.pack.get()) do
    names[p.spec.name or vim.fn.fnamemodify(p.spec.src, ':t:r')] = true
  end
  return names
end

vim.api.nvim_create_user_command('Pack', function()
  local lines = {
    'Installed plugins (vim.pack.get):',
    'Press q to close.',
    '',
    string.format('  %-40s  %-12s  %s', 'name', 'status', 'src'),
    string.format('  %-40s  %-12s  %s', string.rep('-', 40), string.rep('-', 12), string.rep('-', 40)),
  }
  for _, p in ipairs(vim.pack.get()) do
    local name = p.spec.name or vim.fn.fnamemodify(p.spec.src, ':t:r')
    local status = p.active and 'active' or 'inactive'
    table.insert(lines, string.format('  %-40s  %-12s  %s', name, status, p.spec.src))
  end
  vim.cmd('new')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  vim.cmd('file [Pack]')
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = true })
end, { desc = 'Show installed plugins' })

vim.api.nvim_create_user_command('PackClean', function()
  -- Find directories under <data>/site/pack/core/opt/ that aren't in the manifest.
  local pack_dir = vim.fn.stdpath('data') .. '/site/pack/core/opt'
  if vim.fn.isdirectory(pack_dir) == 0 then
    vim.notify('No plugins on disk yet.', vim.log.levels.INFO)
    return
  end
  local managed = manifest_names()
  local unmanaged = {}
  for _, dir in ipairs(vim.fn.readdir(pack_dir)) do
    if not managed[dir] then table.insert(unmanaged, dir) end
  end
  if #unmanaged == 0 then
    vim.notify('Nothing to clean — all plugins on disk are in the manifest.', vim.log.levels.INFO)
    return
  end
  local choice = vim.fn.confirm(
    'Remove unmanaged plugins?\n  ' .. table.concat(unmanaged, '\n  '),
    '&Yes\n&No', 2)
  if choice == 1 then
    vim.pack.del(unmanaged)
    vim.notify(('Removed %d unmanaged plugin(s).'):format(#unmanaged))
  end
end, { desc = 'Remove unmanaged plugins' })
```

- [ ] **Step 2: Verify `:Pack` shows the populated table**

```bash
nvk +'Pack' +qa 2>&1
# Open the file interactively to actually inspect:
nvk
# In nvim: :Pack — confirm a scratch buffer with the table appears. q to close.
```

- [ ] **Step 3: Verify `:PackClean` is a no-op when nothing is unmanaged**

```bash
nvk +'PackClean' +qa 2>&1
```

Expected: `Nothing to clean — all plugins on disk are in the manifest.`

- [ ] **Step 4: Commit**

```bash
git add lua/config/pack.lua
git commit -m "feat(pack): implement :Pack scratch UI and :PackClean

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 13 — Documentation

### Task 25: Rewrite `CLAUDE.md` for the new config

**Files:**
- Modify: `<repo>/CLAUDE.md`

- [ ] **Step 1: Replace the LazyVim-era CLAUDE.md with a vim.pack-era version**

Open `<repo>/CLAUDE.md` and replace its contents with the following. Sections that referenced LazyVim/`lazy.nvim` are rewritten for `vim.pack`. The "Expertise expected" section carries over because it still applies (and is a key teaching artifact).

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim configuration with two goals in tension:

1. **Workhorse** — fast, dependable daily driver for serious engineering work.
2. **Teaching guide** — every customization should be small, readable, and explain *why* it exists, so someone learning nvim can trace "what changes the default behavior, and how."

Optimize for the second goal when they conflict. Prefer a short module with inline comments over a clever one-liner. Prefer a per-language module over a flat config dump.

## Expertise expected when editing this repo

Operate as a senior Neovim engineer with deep, working knowledge of both the editor's internals and its modern Lua ecosystem. Be fluent in:

**Neovim internals**

- The event loop and `vim.uv` (libuv); scheduling, `vim.schedule`, fast-context restrictions.
- The runtime path; how `lua/`, `plugin/`, `ftplugin/`, `after/`, `queries/`, `colors/` are discovered.
- Buffer/window/tab scopes (`vim.bo`, `vim.wo`, `vim.opt_local`, `vim.opt_global`); when to use which.
- Autocmd model: `nvim_create_augroup` with `clear = true`, event ordering, `LspAttach`.
- Keymap layers: `vim.keymap.set`, `<Plug>` mappings, `expr` mappings, when `<leader>` is captured.
- Lua/Vimscript bridge: `vim.fn`, `vim.cmd`, `vim.api.nvim_*`.
- Treesitter: parsers, queries, `vim.treesitter.start`, `:InspectTree`.
- LSP client: `vim.lsp.config` (0.11+ unified API), `LspAttach`, capabilities, `mason-lspconfig`'s `automatic_enable`.
- `:checkhealth`, `:messages`, `vim.print`, `:lua =` as the primary debugging surface.

**Configuration ecosystem (this repo)**

- `vim.pack` is the plugin manager. The full plugin list lives in `lua/config/pack.lua`. There is no auto-merging "extras" layer like LazyVim — anything installed appears in that file.
- `lua/config/lang.lua` aggregates `lua/plugins/lang/*.lua` into one table. Each language module returns `{ servers, formatters_by_ft, linters_by_ft, parsers, mason_tools, extra_plugins }`. To add a language, create one file. To remove one, delete it.
- `lua/plugins/{lsp,coding,treesitter}.lua` are pure consumers of `config.lang` — they do not reference language names directly.
- `tree-sitter-manager.nvim` (active fork) replaces archived `nvim-treesitter`. `nvim-treesitter-textobjects` and `nvim-treesitter-context` are still maintained and live in `plugins/treesitter.lua`.
- `blink.cmp` is the completion engine. `super-tab` preset; the preselect callback suppresses preselect during snippet expansion so `<Tab>` advances snippet fields.
- Snacks bundle (picker, explorer, notifier, dashboard, bigfile, scope) replaces telescope/neo-tree/alpha.

## Layout

- `init.lua` — one line: `require('config')`.
- `lua/config/init.lua` — boot orchestrator. Read top-to-bottom to understand load order.
- `lua/config/options.lua` — `vim.opt.*` settings, each annotated.
- `lua/config/keymaps.lua` — global leader keymaps. LSP keymaps live in `plugins/lsp.lua`'s `LspAttach`.
- `lua/config/autocmds.lua` — yank highlight, restore cursor, etc.
- `lua/config/pack.lua` — `vim.pack.add{}` manifest + `:Pack*` user commands.
- `lua/config/lang.lua` — language aggregator (pure data).
- `lua/plugins/<domain>.lua` — colorscheme, ui, editor, coding, lsp, treesitter, git, ai, picker.
- `lua/plugins/lang/<name>.lua` — one file per language, fixed shape.

## Commands

- `:Pack` — scratch buffer listing installed plugins.
- `:PackUpdate` — `vim.pack.update()` — fetch + apply updates.
- `:PackClean` — remove plugins on disk that are not in the manifest.
- `:PackLog` — last update log (if `:PackUpdate` was run).
- `:Mason` — install/manage LSP servers, formatters, linters.
- `:checkhealth` — first stop for any "plugin doesn't work" report.
- `:LspInfo` / `<leader>cl` — show attached language servers.
- `:DiffviewOpen`, `:DiffviewFileHistory` — in-editor diffs.
- `<leader>m`, `<leader>M`, `[m`, `]m` — Grapple working-set tags.
- `stylua .` — format Lua per `stylua.toml`.

## Conventions for edits

- Each file does one thing. Don't introduce a new top-level domain file for a single small change — extend the closest existing domain file.
- Match the existing style: 2-space indent, 120 cols, `pcall`-wrap third-party `require`s in plugin modules so a missing plugin doesn't kill the whole module.
- When a customization is non-obvious (e.g. the blink.cmp preselect callback), leave a short inline comment explaining *what default behavior is changed and why*.
- LSP keymaps go in `plugins/lsp.lua`'s `LspAttach` callback (buffer-scoped). Picker keymaps go in `plugins/picker.lua`. Custom-plugin keymaps go in their domain file (e.g. Grapple in `editor.lua`).
- Adding a language is creating one file in `lua/plugins/lang/`. The aggregator picks it up automatically.
- Commit each module addition independently. The plan in `docs/plans/` is the reference cadence.

## First run / recovery

- **Fresh clone**: `nvk` (alias for `NVIM_APPNAME=nvim-kickstart nvim`). `vim.pack` clones every plugin on first run.
- **A plugin update broke things**: `:PackLog` to see what changed; revert by editing the manifest's `version` pin and running `:PackUpdate`.
- **Mason missing a tool**: `:lua require('mason-tool-installer').run_on_start()`.
- **Startup feels slow**: `nvim --startuptime /tmp/start.log`; check load order in `lua/config/init.lua`.

This repo has no build, no test runner, and no CI. "Does it work?" = launch nvk, watch for errors, run `:checkhealth`.
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: rewrite CLAUDE.md for vim.pack-era config

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 26: Write a short README

**Files:**
- Modify: `<repo>/README.md`

- [ ] **Step 1: Rewrite README**

```markdown
# nvim

Personal Neovim configuration. Heavily commented, modular, beginner-readable. Native `vim.pack` plugin manager. No LazyVim, no lazy.nvim.

## Quick start

```bash
NVIM_APPNAME=nvim-kickstart nvim
```

Or set the alias:

```fish
alias nvk='NVIM_APPNAME=nvim-kickstart nvim'
```

First launch installs ~30 plugins via `vim.pack`; expect 30-90 seconds. Mason will background-install language servers and formatters after that.

## Architecture

- `init.lua` → `lua/config/init.lua` (boot orchestrator).
- `lua/config/pack.lua` — single plugin manifest.
- `lua/plugins/<domain>.lua` — one file per UI/editor/coding/git/AI domain.
- `lua/plugins/lang/<name>.lua` — one file per language; aggregated by `lua/config/lang.lua`.

See `CLAUDE.md` for the deeper guide and `docs/specs/` for design docs.

## Update / maintain

- `:PackUpdate` — update all plugins.
- `:Mason` — manage LSP servers, formatters, linters.
- `:checkhealth` — diagnose any plugin issue first.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: rewrite README for vim.pack-era config

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Phase 14 — Smoke + readiness

### Task 27: Run the cutover smoke list

**Files:** none modified — verification only.

- [ ] **Step 1: Headless boot exits 0**

```bash
nvk --headless +qa
echo $?
```

Expected: `0`, no `:messages` output.

- [ ] **Step 2: Startup time under 250ms**

```bash
nvk --startuptime /tmp/start.log +qa
tail -1 /tmp/start.log
```

Expected: total time < 250.000 ms. If higher, run `nvk +'Lazy profile' +qa` — wait, that's LazyVim. Use:

```bash
sort -k2 -n /tmp/start.log | tail -10
```

To find the slowest entries.

- [ ] **Step 3: `:checkhealth` clean**

```bash
nvk --headless +'checkhealth' +'wq /tmp/healthcheck.txt' 2>&1
grep -E '^\s*ERROR|^- ERROR' /tmp/healthcheck.txt || echo "No errors"
```

Expected: `No errors`. (Warnings about missing optional tools are fine.)

- [ ] **Step 4: Per-language LSP attach smoke**

For each `lua/plugins/lang/<name>.lua` that declares a server, open a representative file and confirm `:LspInfo` shows the server attached. Manual checklist:

- [ ] `lua` — open `lua/config/options.lua`; lua_ls attaches.
- [ ] `python` — create `/tmp/smoke.py`, open it; pyright attaches.
- [ ] `go` — create `/tmp/smoke.go`, open it; gopls attaches.
- [ ] `rust` — create `/tmp/smoke.rs`, open it; rust-analyzer attaches.
- [ ] `typescript` — create `/tmp/smoke.ts`, open it; vtsls attaches.
- [ ] `json` — create `/tmp/smoke.json`, open it; jsonls attaches.
- [ ] `yaml` — create `/tmp/smoke.yaml`, open it; yamlls attaches.
- [ ] `toml` — create `/tmp/smoke.toml`, open it; taplo attaches.
- [ ] `markdown` — open this README; marksman attaches.
- [ ] `ruby` — create `/tmp/smoke.rb`, open it; ruby_lsp attaches.
- [ ] `cmake` — create `/tmp/CMakeLists.txt`, open it; cmake attaches.
- [ ] `terraform` — create `/tmp/smoke.tf`, open it; terraformls attaches.
- [ ] `docker` — create `/tmp/Dockerfile`, open it; dockerls attaches.
- [ ] `sql` — create `/tmp/smoke.sql`, open it; sqlls attaches.

- [ ] **Step 5: Feature smoke**

- [ ] `<leader>ff` opens picker.
- [ ] `<leader>e` opens explorer.
- [ ] `<leader>gg` opens lazygit.
- [ ] `<C-h/j/k/l>` crosses Zellij panes (if running in Zellij).
- [ ] `<leader>m` tags the current file (Grapple).
- [ ] `<leader>cc` opens Copilot Chat (after `:Copilot auth`).
- [ ] `:InspectTree` shows a tree (treesitter is on).
- [ ] `<leader>gvo` opens Diffview.
- [ ] `<leader>cr` over a symbol triggers inc-rename live preview.
- [ ] `:w` on a Lua file runs stylua (format-on-save).
- [ ] `<leader>uf` toggles autoformat for the current buffer; saving no longer reformats.

- [ ] **Step 6: Begin 3-day dual-running period**

For ≥3 working days, use `nvk` as the daily editor. Note any forced fallback to LazyVim or any feature that doesn't behave as expected. **Do not proceed to Phase 15 until 3 days have passed without forced fallback.**

---

## Phase 15 — Cutover (gated)

### Task 28: Cutover commit on `main`

**Files:**
- Modify (on `main`): `init.lua`, `CLAUDE.md`, `README.md`
- Delete (on `main`): `lazy-lock.json`, `lazyvim.json`, `lua/config/lazy.lua`, `lua/config/options.lua`, `lua/config/keymaps.lua`, `lua/config/autocmds.lua`, `lua/plugins/coding.lua`, `lua/plugins/others.lua`, `lua/plugins/ui.lua`
- Create (on `main`): everything from `<repo>/lua/`, `<repo>/docs/specs/`, `<repo>/docs/plans/` not yet on `main`

**⚠ CONFIRMATION GATE:** Confirm with user that the 3-day dual-running period passed and Task 27's smoke list is fully checked. Do not proceed otherwise.

- [ ] **Step 1 (after confirmation): Land on `main`**

```bash
cd ~/.config/nvim
git switch main
git status                                                   # must be clean
git merge --no-ff feature/kickstart-rewrite -m "$(cat <<'EOF'
feat: cutover to kickstart-style modular config (vim.pack)

Replaces LazyVim + lazy.nvim with a heavily-commented, modular
configuration using native vim.pack and tree-sitter-manager.nvim.
Per-language modules under lua/plugins/lang/ are aggregated by
lua/config/lang.lua and consumed by lsp/coding/treesitter modules.

Spec: docs/specs/2-kickstart-rewrite-design-20260508.md
Plan: docs/plans/2-kickstart-rewrite-20260508.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 2: Verify `main` boots cleanly**

```bash
nvim --headless +qa
echo $?
```

Expected: `0`. (Note: `nvim` here, not `nvk` — at cutover, the new config is the default.)

- [ ] **Step 3: Drop the side-channel**

```bash
rm ~/.config/nvim-kickstart
git -C ~/.config/nvim worktree remove ~/.config/nvim-kickstart-worktree
git branch -d feature/kickstart-rewrite
```

- [ ] **Step 4: Drop the `nvk` alias from fish config**

Edit `~/.config/fish/config.fish`, remove the `alias nvk='NVIM_APPNAME=nvim-kickstart nvim'` line and its preceding comment. Open a new fish shell and verify `type nvk` shows it's gone.

- [ ] **Step 5: Final sanity boot**

```bash
nvim
# Confirm: dashboard appears, <leader>ff works, lua_ls attaches in this very file. :q.
```

---

## Self-review checklist

- [x] **Spec coverage:** Every section of the spec maps to a task in this plan:
  - §5 Architecture → Tasks 4-8 (skeleton + config modules).
  - §6 Integration patterns → Tasks 9-19 (each plugin domain).
  - §7 Keymap inheritance → Task 8 (universal + plugin-mgmt) + per-domain task additions.
  - §8 Error handling → Task 4 step 3 (`pcall` orchestrator) + every plugin module's `pcall`-wrapped `require`.
  - §9 Recovery toolkit → Tasks 7 (stub) + 24 (full implementation).
  - §10 Migration → Tasks 1-3 (branch + worktree + alias) + Task 28 (cutover).
  - §11 Testing → Task 27 (smoke list + 3-day dual-running).
- [x] **Placeholder scan:** No "TODO" / "implement later" / "similar to Task N". `:PackClean` is implemented in Task 24, not deferred. Per-language modules contain complete shapes, not stubs.
- [x] **Type consistency:** `lang.servers`, `lang.formatters_by_ft`, `lang.linters_by_ft`, `lang.parsers`, `lang.mason_tools`, `lang.extra_plugins` — same names used in Task 6 (aggregator), Task 11 (lsp), Task 12 (conform/lint), Task 10 (treesitter), Task 7 (pack), and every `lua/plugins/lang/*.lua` module.
- [x] **Confirmation gates:** Two — Task 2 (worktree) and Task 28 (cutover) — both flagged in-line.

---

## Execution handoff

Plan complete and saved to `docs/plans/2-kickstart-rewrite-20260508.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration. The two confirmation gates (worktree creation in Task 2; cutover in Task 28) bubble back to you regardless.
2. **Inline Execution** — Execute tasks in this session using `superpowers:executing-plans`, batch execution with checkpoints for review.

Which approach?
