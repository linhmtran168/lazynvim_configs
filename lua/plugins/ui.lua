-- ============================================================================
-- UI: statusline (lualine), icons (mini.icons), todo highlights, indent guides.
-- ============================================================================

-- mini.icons: provider for filetype/file/extension icons. Lualine and snacks
-- read this provider via mini.icons.mock_nvim_web_devicons() so plugins that
-- expect the older nvim-web-devicons API still work.
local ok_icons, icons = pcall(require, 'mini.icons')
if ok_icons then
  icons.setup()
  icons.mock_nvim_web_devicons()
end

-- lualine: minimal statusline, everforest theme picks up colors automatically.
local ok_lualine, lualine = pcall(require, 'lualine')
if ok_lualine then
  lualine.setup({
    options = {
      theme = 'everforest',
      -- powerline-style separators: solid arrows between sections, thin arrows
      -- between components within a section (requires a Nerd Font)
      section_separators   = { left = '', right = '' },
      component_separators = { left = '', right = '' },
      globalstatus = true,        -- one statusline at the bottom of all splits
    },
    sections = {
      lualine_a = { 'mode' },
      lualine_b = { 'branch', 'diff', 'diagnostics' },
      lualine_c = { { 'filename', path = 1 } },          -- relative path
      lualine_x = { 'encoding', 'fileformat', 'filetype' },
      lualine_y = { 'progress' },
      lualine_z = { 'location' },
    },
  })
end

-- todo-comments: highlight TODO/FIXME/HACK/NOTE/WARN/PERF in comments and
-- exposes a picker (Snacks integration via :TodoTelescope is replaced — we
-- bind <leader>st to call Snacks.picker.todos when available).
local ok_todo, todo = pcall(require, 'todo-comments')
if ok_todo then
  todo.setup()
  vim.keymap.set('n', '<leader>st', function()
    if Snacks and Snacks.picker and Snacks.picker.todos then
      Snacks.picker.todos()
    else
      vim.cmd('TodoQuickFix')
    end
  end, { desc = 'TODOs' })
end

-- indent-blankline: subtle vertical guides at indent levels.
local ok_ibl, ibl = pcall(require, 'ibl')
if ok_ibl then
  ibl.setup({
    indent = { char = '│' },
    scope  = { enabled = false },  -- Snacks.scope already does this
  })
end

-- which-key: shows pending keymap completions after a configurable delay.
-- Registers group labels so <leader>f, <leader>s, etc. show descriptions.
local ok_wk, wk = pcall(require, 'which-key')
if ok_wk then
  wk.setup({ delay = 300 })
  wk.add({
    { '<leader>b', group = 'buffer' },
    { '<leader>f', group = 'file' },
    { '<leader>s', group = 'search' },
    { '<leader>g', group = 'git' },
    { '<leader>c', group = 'code' },
    { '<leader>l', group = 'pack/lazy' },
    { '<leader>u', group = 'ui/toggle' },
    { '<leader>e', group = 'explorer' },
    { '<leader>m', group = 'marks/grapple' },
  })
end
