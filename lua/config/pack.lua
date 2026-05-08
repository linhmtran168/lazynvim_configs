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
  -- Colorscheme
  { src = 'https://github.com/neanias/everforest-nvim' },

  -- Treesitter
  { src = 'https://github.com/romus204/tree-sitter-manager.nvim' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },

  -- LSP infrastructure
  { src = 'https://github.com/williamboman/mason.nvim' },
  { src = 'https://github.com/williamboman/mason-lspconfig.nvim' },
  { src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
  { src = 'https://github.com/folke/lazydev.nvim' },

  -- Coding
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/mfussenegger/nvim-lint' },
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
  { src = 'https://github.com/smjonas/inc-rename.nvim' },

  -- UI / picker / explorer / notifier (Snacks bundle)
  { src = 'https://github.com/folke/snacks.nvim' },

  -- UI extras
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

  -- Git
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/sindrets/diffview.nvim' },

  -- AI
  { src = 'https://github.com/zbirenbaum/copilot.lua' },
  { src = 'https://github.com/CopilotC-Nvim/CopilotChat.nvim' },
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
