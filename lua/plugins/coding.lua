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
