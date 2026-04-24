# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal [LazyVim](https://www.lazyvim.org/) configuration with two goals in tension:

1. **Workhorse** — fast, dependable daily driver for serious engineering work.
2. **Teaching guide** — every customization should be small, readable, and explain *why* it exists, so someone learning nvim can trace "what changes the default behavior, and how."

Optimize for the second goal when they conflict. Prefer a short spec with an inline comment over a clever one-liner. Prefer overriding one LazyVim opt over copy-pasting a whole plugin block.

## Layout and how LazyVim wires together

- `init.lua` is one line: `require("config.lazy")`. It stays that way.
- `lua/config/lazy.lua` bootstraps lazy.nvim, loads `LazyVim/LazyVim`, then imports every file under `lua/plugins/`. The order matters: LazyVim's defaults are merged first, the local `plugins/` specs layer on top.
- `lua/config/{options,keymaps,autocmds}.lua` are LazyVim's standard extension points. Keep repo-wide editor behavior here rather than in plugin specs; they auto-load on `VeryLazy`, which makes them the right place for small workflow defaults and custom keymaps.
- `lua/plugins/*.lua` each return a list of lazy.nvim specs. A spec whose name matches a LazyVim-provided plugin **merges/overrides** that plugin (tables deep-merge, functions replace). A spec with a new name **adds** one. This is the single most important mental model for editing this repo.
- `lazyvim.json` is the source of truth for which LazyVim **extras** are enabled (langs, copilot, yanky, mini-surround, dial, inc-rename, …). Toggle via `:LazyExtras` — do not hand-edit unless you know why.
- `lazy-lock.json` pins every plugin commit. Commit churn here is expected and should ship with the spec change that caused it. Use `:Lazy restore` to re-pin.
- `.neoconf.json` enables `neodev` so `lua_ls` understands Neovim's runtime + plugin API while editing this config.
- `stylua.toml` — 2-space indent, 120 column. Run `stylua .` before committing Lua.

## Active customizations and the reasoning behind each

Keep this section honest: if you add a plugin or override, add a one-line rationale here.

- **Colorscheme — `everforest`** (`lua/plugins/ui.lua`). Set by overriding `LazyVim/LazyVim`'s `opts.colorscheme` rather than calling `:colorscheme`, so LazyVim's startup ordering still applies. `evergarden` (spring/green variant) and `gruvbox` are installed as ready alternatives — swap by changing the opt, not by adding a new plugin.
- **Completion — `blink.cmp`** (`lua/plugins/coding.lua`). `preset = "super-tab"` makes `<Tab>` do the obvious thing (accept/jump). The `preselect` function suppresses preselect *while a snippet is expanding* so `<Tab>` advances snippet fields instead of picking a completion item. Teaching note: this is why the callback checks `snippet_active({ direction = 1 })`.
- **Window/pane nav — `smart-splits.nvim`** (`lua/plugins/ui.lua`). Eager-loaded (`lazy = false`) because keymaps must beat Zellij's. `<C-hjkl>` moves cursor seamlessly across nvim splits *and* Zellij panes; `<A-hjkl>` resizes with `at_edge = "wrap"`. Auto-detects Zellij — no extra config needed on that side.
- **Picker and explorer — `Snacks`** (`lazyvim.json`, `lua/config/options.lua`). `snacks_picker` and `snacks_explorer` are the primary file/project surface so files, recent buffers, grep, projects, and the explorer panel all stay in LazyVim's native stack.
- **Working set — `grapple.nvim`** (`lua/plugins/ui.lua`, `lua/config/keymaps.lua`). Use tags for the handful of files you bounce between repeatedly; this complements pickers by solving fast return trips instead of discovery.
- **Optional `nvim-cmp` + `cmp-emoji` compatibility** (`lua/plugins/others.lua`). `blink.cmp` is the active engine, but this optional block adds emoji completion if an enabled extra pulls `nvim-cmp` back in. If no enabled extra still uses `nvim-cmp`, delete the block instead of letting it grow.
- **Diff review — `diffview.nvim`** (`lua/plugins/others.lua`, `lua/config/keymaps.lua`). Keep `lazygit` for active repo operations, but use Diffview when you want in-editor diffs and file history review without leaving Neovim.
- **`trouble.nvim`** (`lua/plugins/others.lua`). Only tweak is `use_diagnostic_signs = true` so the list mirrors the gutter.

## Extras currently enabled (`lazyvim.json`)

See `lazyvim.json` for the live list (AI, editor, coding, many langs, util). Changing it is a `:LazyExtras` action, not a manual edit — hand-edits will not round-trip cleanly.

## Commands

- `:Lazy` — plugin manager. Common actions: `sync`, `update`, `check`, `clean`, `restore`.
- `:LazyExtras` — toggle LazyVim extras; writes `lazyvim.json`.
- `:Mason` — install/manage LSP servers, formatters, linters, DAPs.
- `:checkhealth` — **first stop** for any "plugin doesn't work" report. Before editing, run this.
- `:LazyHealth`, `:LazyProfile`, `:LazyLog` — diagnose load order, startup cost, and what updated recently.
- `:DiffviewOpen` / `:DiffviewFileHistory` — review repo diffs and file history inside Neovim.
- `<leader>m`, `<leader>M`, `[m`, `]m` — tag, list, and cycle through the current working set with Grapple.
- `stylua .` — format Lua per `stylua.toml`.

### First run and recovery

- **Fresh clone**: just run `nvim`. `lua/config/lazy.lua` bootstraps lazy.nvim itself, then installs every pinned plugin. Colorscheme fallback is `habamax` until `everforest` is available.
- **A plugin update broke things**: `:Lazy restore` re-pins to the committed `lazy-lock.json`. If the lockfile itself was the bad change, `git checkout HEAD~1 -- lazy-lock.json` then `:Lazy restore`.
- **Startup feels slow**: `:Lazy profile` ranks plugins by load time; `:checkhealth lazy` flags misconfigured specs.

This repo has no build, no test runner, and no CI. "Does it work?" = launch nvim, watch for errors, run `:checkhealth`.

## Conventions for edits

- Match the existing spec style: return a table of specs; keep `opts` declarative; use `keys` / `event` / `cmd` / `ft` for lazy-loading rather than an imperative `config = function()` when possible.
- Prefer overriding LazyVim's bundled plugin via `opts` merge over copy-pasting its full spec — the whole point of LazyVim is that you inherit sensible defaults.
- When a customization is non-obvious (e.g. the blink.cmp preselect callback), leave a short inline comment explaining *what default behavior it is changing and why*. This file only works as a teaching guide if the code does too.
- Don't introduce a new top-level file under `lua/plugins/` for a single small override — extend the topically closest existing file (`ui.lua`, `coding.lua`, `others.lua`).
- Commit `lazy-lock.json` alongside any spec change that moves it.
