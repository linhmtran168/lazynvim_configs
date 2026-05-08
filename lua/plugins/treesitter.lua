-- ============================================================================
-- Treesitter. We use tree-sitter-manager.nvim (active fork) instead of the
-- archived nvim-treesitter mainline.
--
-- tree-sitter-manager handles both parser installation *and* highlighting:
-- with `highlight = true` (the default), it registers its own FileType autocmd
-- that calls vim.treesitter.start() for every installed parser. We therefore
-- do NOT add a second FileType autocmd here — that would double-attach.
--
-- Textobjects + context ship as separate (still active) plugins on top.
--
-- Available command: :TSManager — opens the parser management TUI.
-- (Unlike old nvim-treesitter, there are no :TSInstall/:TSUpdate commands;
-- manage parsers through the TUI or via ensure_installed in setup().)
-- ============================================================================

local lang = require('config.lang')

local ok, tsm = pcall(require, 'tree-sitter-manager')
if ok then
  tsm.setup({
    ensure_installed = lang.parsers, -- empty until lang/*.lua modules land
    auto_install = true,
    -- highlight = true is the default; it registers a FileType autocmd that
    -- calls vim.treesitter.start() for each installed parser automatically.
  })
end

-- Textobjects: af/if for function outer/inner, ac/ic for class.
-- require path is 'nvim-treesitter-textobjects' (matches the lua/ dir name).
local ok_to, to = pcall(require, 'nvim-treesitter-textobjects')
if ok_to then
  to.setup({
    select = {
      enable = true,
      lookahead = true, -- jump forward to next textobject if cursor is not inside one
      keymaps = {
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
  })
end

-- Context: sticky header showing the current function/class scope. 3 lines max
-- so it doesn't dominate the screen on nested code.
local ok_ctx, ctx = pcall(require, 'treesitter-context')
if ok_ctx then
  ctx.setup({ max_lines = 3 })
end

-- ---------- Treesitter manager keymaps ----------------------------------------
-- Only :TSManager exists (no :TSUpdate/:TSInstall — use the TUI instead).
local map = vim.keymap.set
map('n', '<leader>lt', '<cmd>TSManager<cr>', { desc = 'Treesitter: Manager UI' })
