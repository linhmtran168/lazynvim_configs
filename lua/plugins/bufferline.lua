-- ============================================================================
-- bufferline: shows open buffers as tabs along the top, with a separate
-- segment on the right indicating actual vim tab pages (:tabnew workspaces).
--
-- Buffer ≠ tab in vim:
--   * a buffer is a loaded file (in-memory text + filename)
--   * a tab page is a window layout — its own set of splits
-- Most editors only expose buffers and call them "tabs". Vim has both, and
-- they're independent: a single tab page can show many buffers; a single
-- buffer can be visible in many tab pages. Bufferline shows buffers in the
-- main bar and surfaces the tab-page count on the right so :tabnew is
-- visible too.
--
-- Keymaps for vim tab pages live in lua/config/keymaps.lua under <leader><Tab>.
-- Keymaps for bufferline-specific actions (pin, move, close-others) live here.
-- ============================================================================

local ok, bufferline = pcall(require, "bufferline")
if not ok then
  return
end

bufferline.setup({
  options = {
    mode = "buffers", -- "tabs" mode would show tab pages instead — we want both
    themable = true,
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(_, _, diag)
      local icons = { error = " ", warn = " " }
      local s = ""
      if diag.error then
        s = s .. icons.error .. diag.error
      end
      if diag.warning then
        s = s .. (s ~= "" and " " or "") .. icons.warn .. diag.warning
      end
      return s
    end,
    show_buffer_close_icons = false, -- close via <leader>bd, not click
    show_close_icon = false,
    separator_style = "thin",
    always_show_bufferline = false, -- hide the bar when only one buffer is open
    -- Snacks.explorer renders inside a window of filetype "snacks_layout_box";
    -- this offset shifts the bufferline so it doesn't overlap the explorer.
    offsets = {
      { filetype = "snacks_layout_box", text = "Explorer", separator = true },
    },
  },
})

local map = vim.keymap.set

-- Buffer navigation. <S-h>/<S-l> previously called :bprevious/:bnext directly
-- (lua/config/keymaps.lua); routing through bufferline respects pin order and
-- visible sort, which matters once you start pinning.
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })

-- Buffer reordering and pinning.
map("n", "<leader>b[", "<cmd>BufferLineMovePrev<cr>", { desc = "Move Buffer Left" })
map("n", "<leader>b]", "<cmd>BufferLineMoveNext<cr>", { desc = "Move Buffer Right" })
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin/Unpin Buffer" })
map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", { desc = "Close Non-Pinned" })

-- Pick a buffer by letter (BufferLine flashes letters on each tab).
map("n", "<leader>bj", "<cmd>BufferLinePick<cr>", { desc = "Jump to Buffer (pick)" })
