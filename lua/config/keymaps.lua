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

-- ---------- Rename ------------------------------------------------------------
-- inc-rename: live-preview LSP rename of the symbol under cursor.
-- LSP rename without preview lives at <leader>cR (set in plugins/lsp.lua).
map('n', '<leader>cr', function()
  return ':IncRename ' .. vim.fn.expand('<cword>')
end, { expr = true, desc = 'Rename (inc-rename)' })
