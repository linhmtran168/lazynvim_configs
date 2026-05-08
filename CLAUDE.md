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
