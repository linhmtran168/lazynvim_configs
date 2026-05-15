-- ============================================================================
-- Editor enhancements. Each plugin is independent; one failing doesn't break
-- the others. Custom keymaps live here, near the plugin they drive.
-- ============================================================================

local map = vim.keymap.set

-- ---------- mini.surround: ysiw" / ds( / cs'" --------------------------------
local ok_surround, surround = pcall(require, "mini.surround")
if ok_surround then
  surround.setup()
end

-- ---------- mini.ai: better text objects (af, ai, etc.) -----------------------
local ok_ai, ai = pcall(require, "mini.ai")
if ok_ai then
  ai.setup() -- defaults are sensible (n_lines = 500, builtin search method)
end

-- ---------- mini.hipatterns: highlight #FF0066 etc. inline --------------------
local ok_hi, hi = pcall(require, "mini.hipatterns")
if ok_hi then
  hi.setup({
    highlighters = {
      hex_color = hi.gen_highlighter.hex_color(),
    },
  })
end

-- ---------- mini.pairs: auto-close () [] {} "" '' ----------------------------
-- Inserts the closing pair on opening; <BS> deletes both; <CR> inside an empty
-- pair opens a properly-indented block. Defaults are sensible for Lua/Go/TS;
-- per-filetype overrides go in ftplugin/ if a language ever needs them.
local ok_pairs, pairs_mod = pcall(require, "mini.pairs")
if ok_pairs then
  pairs_mod.setup()
end

-- ---------- mini.bracketed: unified ]x / [x motions --------------------------
-- One grammar for navigating buffers (]b), diagnostics (]d), quickfix (]q),
-- jumplist (]j), location list (]l), comments (]c), conflict markers (]x),
-- and more. Replaces a handful of ad-hoc mappings with consistent pairs.
-- See `:h mini.bracketed` for the full target list.
local ok_bracketed, bracketed = pcall(require, "mini.bracketed")
if ok_bracketed then
  bracketed.setup()
end

-- ---------- mini.splitjoin: gS toggles one-line / multi-line arg lists -------
-- Splits `foo(a, b, c)` into one-arg-per-line, or joins it back. Smart about
-- trailing commas and language-specific separators (treesitter-aware where it
-- can be).
local ok_sj, splitjoin = pcall(require, "mini.splitjoin")
if ok_sj then
  splitjoin.setup()
end

-- ---------- mini.operators: gx / gr / gs / gm / g= ---------------------------
-- gx — exchange two regions (mark first with `gxiw`, second with `gxiw` to swap)
-- gr — replace text with register contents WITHOUT polluting the unnamed
--      register (fixes vim's "paste over yanks the replaced text" papercut)
-- gs — sort linewise; gm — multiply/duplicate; g= — evaluate as Lua/Vim expr
-- We disable `gx` because it shadows nvim's built-in "open URL under cursor"
-- (vim.ui.open). The others don't collide with anything in this config.
local ok_ops, operators = pcall(require, "mini.operators")
if ok_ops then
  operators.setup({
    exchange = { prefix = "" }, -- disable gx; keep nvim's URL opener
  })
end

-- ---------- minimap.vim: fast code overview powered by code-minimap ----------
vim.g.minimap_width = 10
-- Use a local autocmd below instead of minimap.vim's global auto-start. The
-- plugin's built-in hook opens on early/special buffers and can hide Snacks'
-- startup dashboard.
vim.g.minimap_auto_start = 0
vim.g.minimap_auto_start_win_enter = 0
vim.g.minimap_highlight_range = 1
vim.g.minimap_highlight_search = 1
vim.g.minimap_git_colors = 1
vim.g.minimap_background_processing = 1
vim.g.minimap_block_filetypes = {
  "fugitive",
  "nerdtree",
  "tagbar",
  "fzf",
  "snacks_dashboard",
  "snacks_layout_box",
  "snacks_picker_input",
  "snacks_picker_list",
  "snacks_picker_preview",
}
vim.g.minimap_close_filetypes = { "snacks_dashboard" }

local function minimap_should_open(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then
    return false
  end

  local buftype = vim.bo[buf].buftype
  local filetype = vim.bo[buf].filetype
  local name = vim.api.nvim_buf_get_name(buf)

  return buftype == "" and name ~= "" and filetype ~= "minimap" and not filetype:find("^snacks_")
end

local function minimap_auto_open()
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[buf].filetype

    if filetype == "snacks_dashboard" then
      vim.cmd("silent! MinimapClose")
      return
    end

    if minimap_should_open(buf) then
      vim.cmd("silent! Minimap")
    end
  end)
end

vim.api.nvim_create_autocmd({ "VimEnter", "BufWinEnter", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("config_minimap", { clear = true }),
  callback = minimap_auto_open,
})

map("n", "<leader>um", "<cmd>MinimapToggle<cr>", { desc = "Toggle Minimap" })
map("n", "<leader>uM", function()
  vim.cmd("Minimap")

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf):lower()
    local ft = vim.bo[buf].filetype:lower()

    if name:find("minimap", 1, true) or ft == "minimap" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  vim.cmd("wincmd l")
end, { desc = "Focus Minimap" })
map("n", "<leader>uR", function()
  vim.cmd("MinimapRefresh")
  vim.cmd("MinimapUpdateHighlight")
end, { desc = "Refresh Minimap" })

-- ---------- dial: <C-a> / <C-x> on dates, booleans, hex, etc. -----------------
local ok_dial = pcall(require, "dial.config")
if ok_dial then
  -- defaults are sensible; no custom group registration needed.
  map("n", "<C-a>", "<Plug>(dial-increment)")
  map("n", "<C-x>", "<Plug>(dial-decrement)")
  map("v", "<C-a>", "<Plug>(dial-increment)")
  map("v", "<C-x>", "<Plug>(dial-decrement)")
end

-- ---------- yanky: persistent yank ring + paste navigation --------------------
local ok_yanky, yanky = pcall(require, "yanky")
if ok_yanky then
  yanky.setup({
    ring = { storage = "shada" }, -- survives nvim restarts via shada file
  })
  map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
  map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
  map("n", "<C-n>", "<Plug>(YankyCycleForward)")
  map("n", "<C-p>", "<Plug>(YankyCycleBackward)")
end

-- ---------- smart-splits: <C-hjkl> across nvim splits AND Zellij panes --------
-- Note on <A-...> resize keymaps: Meta on macOS only fires when the terminal
-- sends Option as ESC+. Works in Zellij and iTerm2 with "Left Option as +Esc";
-- silently does nothing in Terminal.app. If you switch terminals and resize
-- stops working, that's why.
local ok_smart, smart = pcall(require, "smart-splits")
if ok_smart then
  smart.setup({
    at_edge = "wrap",
    -- multiplexer is auto-detected (Zellij in our case).
  })
  map("n", "<C-h>", smart.move_cursor_left, { desc = "Window/pane left" })
  map("n", "<C-j>", smart.move_cursor_down, { desc = "Window/pane down" })
  map("n", "<C-k>", smart.move_cursor_up, { desc = "Window/pane up" })
  map("n", "<C-l>", smart.move_cursor_right, { desc = "Window/pane right" })
  map("n", "<A-h>", smart.resize_left, { desc = "Resize left" })
  map("n", "<A-j>", smart.resize_down, { desc = "Resize down" })
  map("n", "<A-k>", smart.resize_up, { desc = "Resize up" })
  map("n", "<A-l>", smart.resize_right, { desc = "Resize right" })
end

-- ---------- grapple: persistent file tags for the current working set --------
local ok_grapple, grapple = pcall(require, "grapple")
if ok_grapple then
  -- defaults are good; no setup() call required.
  map("n", "<leader>m", function()
    grapple.toggle()
  end, { desc = "Toggle File Tag" })
  map("n", "<leader>M", function()
    grapple.toggle_tags()
  end, { desc = "Open File Tags" })
  map("n", "]m", function()
    grapple.cycle_tags("next")
  end, { desc = "Next File Tag" })
  map("n", "[m", function()
    grapple.cycle_tags("prev")
  end, { desc = "Prev File Tag" })
  for i = 1, 4 do
    map("n", "<leader>" .. i, function()
      grapple.select({ index = i })
    end, { desc = "Jump to Tag " .. i })
  end
end

-- ---------- macOS clipboard yank in visual ------------------------------------
map("v", "<D-c>", '"+y', { noremap = true, silent = true, desc = "Copy to system clipboard" })
