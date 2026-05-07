# Kickstart-style modular rewrite — design

**Date:** 2026-05-08
**Status:** Approved (pending spec review)
**Topic:** Replace LazyVim + lazy.nvim with a modular, heavily-commented configuration that uses native `vim.pack` and `tree-sitter-manager.nvim`, while preserving the user's current daily feature set.

## 1. Context

The current `~/.config/nvim/` is a LazyVim configuration (lazy.nvim manager, ~25 LazyVim extras enabled, three small plugin override files plus `lua/config/{options,keymaps,autocmds,lazy}.lua`). It is the user's daily editor.

LazyVim handles a lot of glue under the hood — auto-installing LSP servers via `mason-lspconfig` from each enabled lang extra, wiring `conform.nvim` and `nvim-lint` per filetype, picking sensible defaults for snacks pickers, exposing a wide `<leader>` keymap surface, etc. Removing lazy.nvim means removing LazyVim, which means hand-replicating that glue.

The user wants:

1. The *features* of the current config preserved — same colorscheme (`everforest`), same picker stack (Snacks), same completion engine (`blink.cmp`), same git tooling (lazygit + diffview), same window/pane navigation (smart-splits), same working-set tool (Grapple), same AI tooling (Copilot), same per-language LSP/formatter/linter/parser coverage minus Zig.
2. A *kickstart-style* learning surface — modular files, heavy comments explaining what each customization does and why, beginner-readable.
3. Native `vim.pack` (Neovim 0.12+) instead of `lazy.nvim`.
4. `romus204/tree-sitter-manager.nvim` instead of the archived `nvim-treesitter` mainline.
5. A new branch from `main`; final cutover is a merge.

## 2. Goals & non-goals

**Goals**

- Modular layout where one file = one domain.
- Heavy inline comments — readable without prior nvim experience.
- Preserve the user's confirmed muscle-memory keymap set.
- Per-language modules return a single shape consumed by LSP, formatters, linters, parsers, and per-language extra plugins.
- Side-by-side rollout via `NVIM_APPNAME=nvim-kickstart` so the current LazyVim editor remains the daily driver until cutover.

**Non-goals**

- Pure kickstart parity (telescope, neo-tree, nvim-cmp, etc. — the user's stack stays).
- Zig support (dropped per user request).
- Adding tests, CI, or a build system. The repo has none today; the new config matches that.
- Generic plugin-manager UI parity with `:Lazy`. We add a minimal `:Pack` scratch buffer, not a clone.

## 3. Constraints

- **Neovim ≥ 0.12** (already confirmed). `vim.pack.add{}`, `vim.pack.update()`, `vim.lsp.config()`, and `vim.diagnostic.jump()` are all available.
- **Daily-driver safety.** Cannot risk the editor breaking mid-task. Side-channel rollout is mandatory.
- **`stylua.toml`** carries over: 2-space indent, 120 columns.
- **The user's global preference** says `git worktree add` requires explicit confirmation each time — implementation plan must call this out.

## 4. Decisions (confirmed during brainstorming)

| # | Question | Choice |
|---|---|---|
| 1 | Scope of rewrite | (b) My-stack, kickstart-style |
| 2 | Neovim version | 0.12+ confirmed |
| 3 | Language coverage | All 14 current languages (15 extras minus zig); add `lua` for self-editing → 15 lang modules |
| 4 | Rollout strategy | (a) `NVIM_APPNAME=nvim-kickstart` via worktree at `~/.config/nvim-kickstart-worktree/` |
| 5 | Keymap inheritance | (c) Hybrid keep-list (see §7) |
| 6 | Module layout | (B) Domain-modular |
| 7 | `vim.pack` usage | (ii) Central manifest in `config/pack.lua` + decentralized config |
| 8 | Per-language wiring | (II) Per-language modules aggregated by `config/lang.lua` |
| 9 | `mason-lspconfig automatic_enable` | `true` |
| 10 | `format_on_save` | On by default, with `<leader>uf`/`<leader>uF` toggles (buffer/global) |
| 11 | `<leader>cr` conflict | inc-rename owns it; LSP rename moves to `<leader>cR` |
| 12 | Plugin/parser-mgmt keymaps | `<leader>l*` namespace (see §7) |
| 13 | Cutover criteria | 3 working days dual-running + checkhealth + smoke list (§10) |
| 14 | Lockfile handling | `git rm lazy-lock.json` in cutover commit; rely on git history |

## 5. Architecture

### 5.1 File tree

```
~/.config/nvim/                           # working tree on feature/kickstart-rewrite
├── init.lua                              # one line: require('config')
├── stylua.toml                           # carry over
├── .neoconf.json                         # carry over (neodev for lua_ls)
├── README.md                             # short, points to module map
├── CLAUDE.md                             # rewritten for the new config
├── docs/
│   ├── specs/
│   └── plans/
├── after/
│   └── ftplugin/                         # only if a lang needs ft-local opts not covered by setup()
└── lua/
    ├── config/
    │   ├── init.lua                      # boot orchestrator
    │   ├── options.lua                   # vim.opt.*
    │   ├── keymaps.lua                   # global leader keymaps (NOT LSP)
    │   ├── autocmds.lua                  # highlight on yank, restore cursor, etc.
    │   ├── pack.lua                      # vim.pack manifest + :Pack* commands
    │   └── lang.lua                      # aggregator: reads plugins/lang/*.lua
    └── plugins/
        ├── colorscheme.lua               # everforest
        ├── ui.lua                        # snacks (notifier/dashboard/bigfile/scope), lualine, mini.icons, todo-comments, indent-blankline
        ├── editor.lua                    # mini.surround, mini.ai, dial, yanky, mini.hipatterns, smart-splits, grapple
        ├── coding.lua                    # blink.cmp, conform, nvim-lint, inc-rename
        ├── lsp.lua                       # mason, mason-tool-installer, lspconfig glue, LspAttach keymaps
        ├── treesitter.lua                # tree-sitter-manager, ts-textobjects, ts-context
        ├── git.lua                       # gitsigns, diffview
        ├── ai.lua                        # copilot, copilot-chat
        ├── picker.lua                    # snacks.picker + snacks.explorer + picker keymaps
        └── lang/
            ├── cmake.lua
            ├── docker.lua
            ├── git.lua
            ├── go.lua
            ├── json.lua
            ├── lua.lua                   # added: we edit Lua here
            ├── markdown.lua
            ├── python.lua
            ├── ruby.lua
            ├── rust.lua
            ├── sql.lua
            ├── terraform.lua
            ├── toml.lua
            ├── typescript.lua
            └── yaml.lua
```

Total: 6 config files + 9 domain plugin files + 15 language files = 30 lua files. No file expected over ~120 lines.

### 5.2 Boot sequence

`init.lua` → `require('config')` → `lua/config/init.lua` runs steps in order:

```
 1. require('config.options')         vim.opt set early so plugins observe correct values
    set vim.g.mapleader / maplocalleader     (must precede any `keys = { ... }` evaluation)
 2. require('config.lang')            load lang/*.lua into one in-memory table; pure data, no side effects
 3. require('config.pack')            vim.pack.add{}; blocks on first run while git-cloning
 4. require('plugins.colorscheme')    set first so subsequent setup() picks correct hl groups
 5. require('plugins.treesitter')     parsers ready early; many plugins assume TS is available
 6. require('plugins.ui')
 7. require('plugins.editor')
 8. require('plugins.coding')
 9. require('plugins.picker')
10. require('plugins.git')
11. require('plugins.ai')
12. require('plugins.lsp')            last; reads config.lang for servers list
13. require('config.keymaps')         after plugins so plugin-defined commands exist
14. require('config.autocmds')
```

Each `require('plugins.*')` is `pcall`-wrapped so a single broken module never aborts startup.

## 6. Integration patterns

### 6.1 `lua/config/pack.lua` — the single plugin manifest

```lua
local lang = require('config.lang')

vim.pack.add({
  -- Treesitter manager (must precede plugins.treesitter)
  { src = 'https://github.com/romus204/tree-sitter-manager.nvim' },

  -- Colorscheme
  { src = 'https://github.com/neanias/everforest-nvim' },

  -- UI
  { src = 'https://github.com/folke/snacks.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/echasnovski/mini.icons' },
  { src = 'https://github.com/folke/todo-comments.nvim' },
  { src = 'https://github.com/lukas-reineke/indent-blankline.nvim' },

  -- Editor
  { src = 'https://github.com/echasnovski/mini.surround' },
  { src = 'https://github.com/echasnovski/mini.ai' },
  { src = 'https://github.com/echasnovski/mini.hipatterns' },
  { src = 'https://github.com/monaqa/dial.nvim' },
  { src = 'https://github.com/gbprod/yanky.nvim' },
  { src = 'https://github.com/mrjones2014/smart-splits.nvim' },
  { src = 'https://github.com/cbochs/grapple.nvim' },

  -- Coding
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-lint' },
  { src = 'https://github.com/smjonas/inc-rename.nvim' },

  -- LSP
  { src = 'https://github.com/williamboman/mason.nvim' },
  { src = 'https://github.com/williamboman/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/folke/lazydev.nvim' },

  -- Treesitter ecosystem (still maintained as separate repos)
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },

  -- Git
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/sindrets/diffview.nvim' },

  -- AI
  { src = 'https://github.com/zbirenbaum/copilot.lua' },
  { src = 'https://github.com/CopilotC-Nvim/CopilotChat.nvim' },
})

if lang.extra_plugins and #lang.extra_plugins > 0 then
  vim.pack.add(lang.extra_plugins)
end

-- :Pack / :PackUpdate / :PackClean / :PackLog user commands defined here.
```

### 6.2 `lua/plugins/lang/<n>.lua` — the contract

Every language file returns the same shape; empty fields are optional.

```lua
return {
  servers          = { gopls = { settings = { gopls = { gofumpt = true } } } },
  formatters_by_ft = { go = { 'gofumpt', 'goimports' } },
  linters_by_ft    = { go = { 'golangcilint' } },
  parsers          = { 'go', 'gomod', 'gosum', 'gowork' },
  mason_tools      = { 'gopls', 'gofumpt', 'goimports', 'golangci-lint' },
  extra_plugins    = { { src = 'https://github.com/leoluz/nvim-dap-go' } },
}
```

### 6.3 `lua/config/lang.lua` — aggregator

Reads every `lua/plugins/lang/*.lua`, merges into:

```lua
{
  servers = { ... },           -- consumed by plugins.lsp
  formatters_by_ft = { ... },  -- consumed by plugins.coding (conform)
  linters_by_ft = { ... },     -- consumed by plugins.coding (nvim-lint)
  parsers = { ... },           -- consumed by plugins.treesitter
  mason_tools = { ... },       -- consumed by plugins.lsp (mason-tool-installer)
  extra_plugins = { ... },     -- consumed by config.pack
}
```

This module is pure — no side effects.

### 6.4 `lua/plugins/lsp.lua`

- `require('mason').setup()`
- `require('mason-tool-installer').setup({ ensure_installed = lang.mason_tools })`
- For each `name, opts` in `lang.servers`: `vim.lsp.config(name, opts)` (Neovim 0.11+ unified API).
- `require('mason-lspconfig').setup({ ensure_installed = vim.tbl_keys(lang.servers), automatic_enable = true })`
- `LspAttach` autocmd installs LSP-only keymaps buffer-locally (`gd`, `gr`, `gI`, `gy`, `K`, `gK`, `<leader>ca`, `<leader>cR`, `<leader>cf`, `<leader>cl`, `<leader>cd`, `]d`/`[d`).

### 6.5 `lua/plugins/treesitter.lua`

- `require('tree-sitter-manager').setup({ ensure_installed = lang.parsers, auto_install = true })`.
- `FileType` autocmd calls `vim.treesitter.start(buf, ft)` when the parser is available — this is what produces highlighting under the new model.
- `require('nvim-treesitter-textobjects').setup({ select = { keymaps = { ['af']='@function.outer', ... } } })`
- `require('treesitter-context').setup({ max_lines = 3 })`
- `<leader>lt*` keymaps wire to whatever `tree-sitter-manager` exposes (verified against its README during implementation).

### 6.6 `lua/plugins/coding.lua`

```lua
local lang = require('config.lang')

require('conform').setup({
  formatters_by_ft = lang.formatters_by_ft,
  format_on_save = function(buf)
    if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
    return { lsp_format = 'fallback', timeout_ms = 2000 }
  end,
})

require('lint').linters_by_ft = lang.linters_by_ft
vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
  callback = function() require('lint').try_lint() end,
})

require('blink.cmp').setup({
  keymap = { preset = 'super-tab' },
  sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
  -- preselect callback that suppresses preselect during snippet expansion,
  -- ported verbatim from the current lua/plugins/coding.lua.
})

require('inc_rename').setup()
```

## 7. Keymap inheritance — the keep-list

LSP keymaps live in `plugins/lsp.lua`'s `LspAttach` callback (buffer-scoped). Everything else lives in `lua/config/keymaps.lua`, organized by section comments.

**Universal editor defaults**

- `j`/`k`/`<Down>`/`<Up>` with `gj`/`gk`
- `n`/`N` keep-centered (`zv`)
- `<esc>` clears search highlight + closes notifications
- `<C-s>` save file
- `<` / `>` in visual stay-selected
- `gco`/`gcO` add comment below/above
- `<leader>fn` new file
- `<leader>qq` quit all
- `<leader>-` / `<leader>|` split below/right
- `,` `.` `;` insert-mode undo breakpoints

**Buffers**

- `<S-h>` / `<S-l>` / `[b` / `]b` prev/next buffer
- `<leader>bb` and `` <leader>` `` switch-to-other-buffer
- `<leader>bd` / `<leader>bD` / `<leader>bo` delete buffer / buffer+window / others

**Diagnostics & quickfix**

- `<leader>cd` line diag float
- `]d`/`[d`, `]e`/`[e`, `]w`/`[w`
- `[q`/`]q` quickfix; `<leader>xl`/`<leader>xq` open lists
- `<leader>xx` / `<leader>xX` Trouble (workspace / buffer)

**LSP (`LspAttach`)**

- `gd`, `gr`, `gI`, `gy`, `gD`
- `K`, `gK` (NOT `<C-k>` — collides with smart-splits)
- `<leader>ca`, `<leader>cR` (LSP rename — inc-rename owns `<leader>cr`), `<leader>cf`, `<leader>cl`
- `<leader>cd`, `]d`/`[d`

**Pickers (Snacks)**

- `<leader>ff` / `<leader>fF` / `<leader>fr` / `<leader>fb` / `<leader>fc` / `<leader>fp`
- `<leader>sg` / `<leader>sw` / `<leader>sh` / `<leader>sk` / `<leader>sd` / `<leader>sD` / `<leader>sr` / `<leader>ss` / `<leader>sS`
- `<leader>:` command history
- `<leader>e` / `<leader>E` explorer

**Git**

- `<leader>gg` / `<leader>gG` lazygit (root / cwd)
- `<leader>gb` blame, `<leader>gf` file history, `<leader>gl`/`<leader>gL` git log
- `<leader>gB` browse open, `<leader>gY` browse yank
- `<leader>gvo` / `<leader>gvc` / `<leader>gvf` / `<leader>gvh` Diffview

**Custom carryover**

- Grapple — `<leader>m`, `<leader>M`, `[m`, `]m`, `<leader>1` … `<leader>4`
- Smart-splits — `<C-h/j/k/l>` move, `<A-h/j/k/l>` resize
- `<D-c>` system clipboard yank in visual
- `` <C-`> `` terminal toggle, `` <leader>t` `` terminal at root

**Format-on-save toggles** (carved back in)

- `<leader>uf` toggle buffer-local autoformat
- `<leader>uF` toggle global autoformat

**`<leader>l*` plugin & parser management** (replaces LazyVim's `<leader>l`)

- `<leader>ll` `:Pack` UI
- `<leader>lu` `:PackUpdate`
- `<leader>lc` `:PackClean`
- `<leader>lL` `:PackLog`
- `<leader>lt` tree-sitter-manager UI
- `<leader>ltu` update parsers
- `<leader>lti` install parser

**Dropped** (per user's "long tail" preference)

- All other `<leader>u*` UI toggles (spell, wrap, conceal, dim, animate, indent, scroll, zen, zoom, inspect, …)
- All `<leader><tab>*` tab ops
- `<A-j>`/`<A-k>` line-move (collides with smart-splits resize)
- LazyVim's `<C-h/j/k/l>` window jumps (smart-splits already covers this and crosses Zellij panes)
- `<leader>L` LazyVim news
- `<leader>K` Keywordprg, profiler toggles, terminal duplicates

## 8. Error handling

Three-layer absorption:

1. **`config/init.lua` orchestrator.** Each `require('plugins.X')` is `pcall`-wrapped; on failure, `vim.notify` at ERROR level. A broken plugin module does not abort startup.
2. **Inside each plugin module.** `setup()` calls are individually `pcall`-wrapped so one bad spec doesn't kill the whole module.
3. **Inside `LspAttach`.** Naturally buffer-scoped — a broken server attach doesn't propagate.

`vim.pack.add{}` is **not** wrapped. If pack can't fetch, we want the loud error.

## 9. Recovery toolkit (LazyVim → vim.pack equivalents)

| LazyVim                  | New equivalent                                                        |
|---|---|
| `:Lazy`                  | `:Pack` (custom scratch-buffer UI) or `:lua = vim.pack.get()`         |
| `:Lazy update`           | `:PackUpdate` → `vim.pack.update()`                                   |
| `:Lazy restore`          | `vim.pack.update({}, { force_version = true })` — pinning via `version = vim.version.range(...)` |
| `:Lazy clean`            | `:PackClean` (custom; diffs `vim.pack.get()` against manifest, calls `vim.pack.del{}`) |
| `:Lazy log`              | `:PackLog` (custom; tails per-update log)                             |
| `:Lazy profile`          | `nvim --startuptime /tmp/start.log`                                   |

## 10. Migration / rollout plan

### 10.1 Filesystem layout during migration

- `~/.config/nvim/` → `main` branch (LazyVim) — **untouched until cutover**.
- `~/.config/nvim-kickstart-worktree/` → git worktree of `feature/kickstart-rewrite`.
- `~/.config/nvim-kickstart/` → symlink to the worktree above.
- `NVIM_APPNAME=nvim-kickstart nvim` (alias `nvk`) launches the new config.
- Separate `~/.local/share/nvim-kickstart/` data dir prevents pack/mason state collision.

The `git worktree add` step requires explicit user confirmation per the user's global preference.

### 10.2 Cutover criteria — all must hold

1. `nvk` cold-start under 250ms (`nvim --startuptime`). LazyVim baseline measured for reference, not as a binding constraint.
2. `:checkhealth` clean (no errors, only expected warnings).
3. Manual smoke list passes (Go: gopls + gofumpt + goimports; pickers; lazygit; smart-splits crossing Zellij; Grapple; Copilot inline + chat; Treesitter highlighting; Diffview; per-language LSP attach for each `lang/*.lua`).
4. ≥ 3 working days of dual-running with no forced fallback to LazyVim.

### 10.3 Cutover commit

In a single commit on `main`:

- `git rm lazy-lock.json lazyvim.json lua/config/lazy.lua`
- Replace `init.lua`, `lua/config/*`, `lua/plugins/*` with the new tree.
- Rewrite `CLAUDE.md` for the new config (architecture, pack workflow, recovery, expertise still applies).
- Drop the worktree + symlink.

History retains the old LazyVim files; rollback is `git revert <cutover>`.

## 11. Testing strategy

No test framework added. Verification is empirical and manual:

- `stylua --check .` before each commit.
- `nvk --headless +qa` exits 0 (smoke check).
- `nvk --headless +'checkhealth' +'wq /tmp/healthcheck.txt'` and grep for `ERROR`.
- Per-language smoke list (one file per `lang/*.lua`, confirm LSP attach + format).

The implementation plan converts the smoke list into a checklist task.

## 12. Out of scope

- Tests, CI, build system.
- Zig support.
- Pure kickstart parity (telescope, neo-tree, nvim-cmp, etc. — not in user's stack).
- Generic `:Lazy`-clone UI; `:Pack` is intentionally minimal.
- Migrating any future personal plugins not currently in the LazyVim setup.

## 13. Open questions

None remaining. All decisions logged in §4.
