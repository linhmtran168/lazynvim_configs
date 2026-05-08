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
  dashboard = {
    enabled = true,
    -- The default `startup` section calls require('lazy.stats') which doesn't
    -- exist — we use vim.pack, not lazy.nvim. Provide explicit sections that
    -- skip lazy stats but keep file/project navigation.
    sections = {
      { section = 'header' },
      { icon = ' ', title = 'Keymaps',      section = 'keys',         indent = 2, padding = 1 },
      { icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
      { icon = ' ', title = 'Projects',     section = 'projects',     indent = 2, padding = 1 },
    },
  },
  bigfile   = { enabled = true },
  scope     = { enabled = true },
  input     = { enabled = true },
  scroll    = { enabled = false },  -- turn on if you want smooth scrolling
  terminal  = { enabled = true },   -- floating terminal toggled via <C-/>
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

-- ---------- Buffer list (<leader>bl) -----------------------------------------
-- Alias for <leader>fb so the buffer group has an obvious shortcut.
map('n', '<leader>bl', function() Snacks.picker.buffers() end, { desc = 'Buffer List' })

-- ---------- Terminal (<C-/>) --------------------------------------------------
-- <C-/> toggles a floating terminal in both normal and terminal mode.
-- <Esc><Esc> exits terminal mode without closing it.
map({ 'n', 't' }, '<C-`>', function() Snacks.terminal.toggle() end, { desc = 'Toggle Terminal' })
map('t', '<Esc><Esc>',   '<C-\\><C-n>', { desc = 'Exit Terminal Mode' })
map('t', '<C-c><C-c>', '<C-\\><C-n>', { desc = 'Exit Terminal Mode' })

-- ---------- Explorer (<leader>e) ----------------------------------------------
map('n', '<leader>e', function() Snacks.explorer() end,                              { desc = 'Explorer (root)' })
map('n', '<leader>E', function() Snacks.explorer({ cwd = vim.uv.cwd() }) end,        { desc = 'Explorer (cwd)' })
