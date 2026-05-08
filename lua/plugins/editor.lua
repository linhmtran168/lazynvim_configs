-- ============================================================================
-- Editor enhancements. Each plugin is independent; one failing doesn't break
-- the others. Custom keymaps live here, near the plugin they drive.
-- ============================================================================

local map = vim.keymap.set

-- ---------- mini.surround: ysiw" / ds( / cs'" --------------------------------
local ok_surround, surround = pcall(require, 'mini.surround')
if ok_surround then surround.setup() end

-- ---------- mini.ai: better text objects (af, ai, etc.) -----------------------
local ok_ai, ai = pcall(require, 'mini.ai')
if ok_ai then ai.setup({ n_lines = 500 }) end

-- ---------- mini.hipatterns: highlight #FF0066 etc. inline --------------------
local ok_hi, hi = pcall(require, 'mini.hipatterns')
if ok_hi then
  hi.setup({
    highlighters = {
      hex_color = hi.gen_highlighter.hex_color(),
    },
  })
end

-- ---------- dial: <C-a> / <C-x> on dates, booleans, hex, etc. -----------------
local ok_dial = pcall(require, 'dial.config')
if ok_dial then
  -- defaults are sensible; no custom group registration needed.
  map('n', '<C-a>', '<Plug>(dial-increment)')
  map('n', '<C-x>', '<Plug>(dial-decrement)')
  map('v', '<C-a>', '<Plug>(dial-increment)')
  map('v', '<C-x>', '<Plug>(dial-decrement)')
end

-- ---------- yanky: persistent yank ring + paste navigation --------------------
local ok_yanky, yanky = pcall(require, 'yanky')
if ok_yanky then
  yanky.setup({
    ring = { storage = 'shada' }, -- survives nvim restarts via shada file
  })
  map({ 'n', 'x' }, 'p', '<Plug>(YankyPutAfter)')
  map({ 'n', 'x' }, 'P', '<Plug>(YankyPutBefore)')
  map('n', '<C-n>', '<Plug>(YankyCycleForward)')
  map('n', '<C-p>', '<Plug>(YankyCycleBackward)')
end

-- ---------- smart-splits: <C-hjkl> across nvim splits AND Zellij panes --------
local ok_smart, smart = pcall(require, 'smart-splits')
if ok_smart then
  smart.setup({
    at_edge = 'wrap',
    -- multiplexer is auto-detected (Zellij in our case).
  })
  map('n', '<C-h>', smart.move_cursor_left, { desc = 'Window/pane left' })
  map('n', '<C-j>', smart.move_cursor_down, { desc = 'Window/pane down' })
  map('n', '<C-k>', smart.move_cursor_up, { desc = 'Window/pane up' })
  map('n', '<C-l>', smart.move_cursor_right, { desc = 'Window/pane right' })
  map('n', '<A-h>', smart.resize_left, { desc = 'Resize left' })
  map('n', '<A-j>', smart.resize_down, { desc = 'Resize down' })
  map('n', '<A-k>', smart.resize_up, { desc = 'Resize up' })
  map('n', '<A-l>', smart.resize_right, { desc = 'Resize right' })
end

-- ---------- grapple: persistent file tags for the current working set --------
local ok_grapple, grapple = pcall(require, 'grapple')
if ok_grapple then
  -- defaults are good; no setup() call required.
  map('n', '<leader>m', function() grapple.toggle() end, { desc = 'Toggle File Tag' })
  map('n', '<leader>M', function() grapple.toggle_tags() end, { desc = 'Open File Tags' })
  map('n', ']m', function() grapple.cycle_tags('next') end, { desc = 'Next File Tag' })
  map('n', '[m', function() grapple.cycle_tags('prev') end, { desc = 'Prev File Tag' })
  for i = 1, 4 do
    map('n', '<leader>' .. i, function() grapple.select({ index = i }) end, { desc = 'Jump to Tag ' .. i })
  end
end

-- ---------- macOS clipboard yank in visual ------------------------------------
map('v', '<D-c>', '"+y', { noremap = true, silent = true, desc = 'Copy to system clipboard' })
