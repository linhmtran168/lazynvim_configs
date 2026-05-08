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
