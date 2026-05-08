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

local lang = require("config.lang")

-- Version pinning policy:
--   * `version = "stable"` / `"release"` — moving tag the maintainer updates to
--     the latest stable release (folke, conform, which-key, gitsigns).
--   * `vim.version.range("N.*")` — track major N, accept minor/patch updates.
--   * `vim.version.range("0.X.*")` — for pre-1.0 plugins where minor bumps
--     break (mini.*, grapple). Bump the minor manually after reading CHANGELOG.
--   * No `version` — plugin lacks meaningful semver; floats on default branch.
vim.pack.add({
  -- Colorscheme
  { src = "https://github.com/neanias/everforest-nvim" },

  -- Treesitter (no semver — active fork; tracks default branch)
  { src = "https://github.com/romus204/tree-sitter-manager.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },

  -- LSP infrastructure
  { src = "https://github.com/williamboman/mason.nvim" },
  { src = "https://github.com/williamboman/mason-lspconfig.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/folke/lazydev.nvim" },

  -- Coding
  { src = "https://github.com/stevearc/conform.nvim", version = "stable" },
  { src = "https://github.com/mfussenegger/nvim-lint" },
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  { src = "https://github.com/smjonas/inc-rename.nvim" },

  -- UI / picker / explorer / notifier (Snacks bundle)
  { src = "https://github.com/folke/snacks.nvim", version = "stable" },

  -- UI extras
  -- lualine has no real semver — only `compat-nvim-*` markers; floats.
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  { src = "https://github.com/echasnovski/mini.icons", version = vim.version.range("0.17.*") },
  { src = "https://github.com/folke/todo-comments.nvim" },
  { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
  { src = "https://github.com/folke/which-key.nvim", version = "stable" },

  -- Editor
  { src = "https://github.com/echasnovski/mini.surround", version = vim.version.range("0.17.*") },
  { src = "https://github.com/echasnovski/mini.ai", version = vim.version.range("0.17.*") },
  { src = "https://github.com/echasnovski/mini.hipatterns", version = vim.version.range("0.17.*") },
  { src = "https://github.com/monaqa/dial.nvim" },
  { src = "https://github.com/gbprod/yanky.nvim", version = vim.version.range("2.*") },
  { src = "https://github.com/mrjones2014/smart-splits.nvim" },
  { src = "https://github.com/cbochs/grapple.nvim", version = vim.version.range("0.30.*") },

  -- Git
  { src = "https://github.com/lewis6991/gitsigns.nvim", version = "release" },
  { src = "https://github.com/sindrets/diffview.nvim" },

  -- AI
  { src = "https://github.com/nvim-lua/plenary.nvim" }, -- required by CopilotChat
  { src = "https://github.com/zbirenbaum/copilot.lua" },
  { src = "https://github.com/CopilotC-Nvim/CopilotChat.nvim" },
})

-- Append per-language extra_plugins so they land in the same install pass.
if lang.extra_plugins and #lang.extra_plugins > 0 then
  vim.pack.add(lang.extra_plugins)
end

-- ----------------------------------------------------------------------------
-- :Pack* commands — minimal lazy.nvim parity.
-- ----------------------------------------------------------------------------

-- Helper: read the manifest's set of plugin names by re-reading vim.pack.get()
-- after vim.pack.add has run. (vim.pack tracks every plugin we've registered.)
local function manifest_names()
  local names = {}
  for _, p in ipairs(vim.pack.get()) do
    names[p.spec.name or vim.fn.fnamemodify(p.spec.src, ":t:r")] = true
  end
  return names
end

-- :Pack — scratch buffer listing installed plugins with version + status.
vim.api.nvim_create_user_command("Pack", function()
  local lines = {
    "Installed plugins (vim.pack.get):",
    "Press q to close.",
    "",
    string.format("  %-40s  %-12s  %s", "name", "status", "src"),
    string.format("  %-40s  %-12s  %s", string.rep("-", 40), string.rep("-", 12), string.rep("-", 40)),
  }
  for _, p in ipairs(vim.pack.get()) do
    local name = p.spec.name or vim.fn.fnamemodify(p.spec.src, ":t:r")
    local status = p.active and "active" or "inactive"
    table.insert(lines, string.format("  %-40s  %-12s  %s", name, status, p.spec.src))
  end
  vim.cmd("new")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.modifiable = false
  vim.cmd("file [Pack]")
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = true })
end, { desc = "Show installed plugins" })

-- :PackUpdate — fetch + apply updates for everything in the manifest.
vim.api.nvim_create_user_command("PackUpdate", function()
  vim.pack.update()
end, { desc = "Update all plugins" })

-- :PackClean — remove plugins present on disk but absent from the manifest.
-- Compares vim.pack.get() against names referenced in the manifest call(s).
vim.api.nvim_create_user_command("PackClean", function()
  -- Find directories under <data>/site/pack/core/opt/ that aren't in the manifest.
  local pack_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt"
  if vim.fn.isdirectory(pack_dir) == 0 then
    vim.notify("No plugins on disk yet.", vim.log.levels.INFO)
    return
  end
  local managed = manifest_names()
  local unmanaged = {}
  for _, dir in ipairs(vim.fn.readdir(pack_dir)) do
    if not managed[dir] then
      table.insert(unmanaged, dir)
    end
  end
  if #unmanaged == 0 then
    vim.notify("Nothing to clean — all plugins on disk are in the manifest.", vim.log.levels.INFO)
    return
  end
  local choice = vim.fn.confirm("Remove unmanaged plugins?\n  " .. table.concat(unmanaged, "\n  "), "&Yes\n&No", 2)
  if choice == 1 then
    vim.pack.del(unmanaged)
    vim.notify(("Removed %d unmanaged plugin(s)."):format(#unmanaged))
  end
end, { desc = "Remove unmanaged plugins" })

-- :PackLog — tail the most recent update log written by :PackUpdate.
vim.api.nvim_create_user_command("PackLog", function()
  local log = vim.fn.stdpath("data") .. "/pack-update.log"
  if vim.fn.filereadable(log) == 1 then
    vim.cmd("tabnew " .. log)
  else
    vim.notify("No PackLog yet — run :PackUpdate first", vim.log.levels.INFO)
  end
end, { desc = "Show last update log" })
