-- ============================================================================
-- Autocmds. Each group uses `clear = true` so re-`require`-ing this module
-- (e.g. via :source %) doesn't double-register handlers.
-- ============================================================================

local function group(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end

-- Briefly highlight yanked text — visual confirmation that the yank happened.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group("yank_highlight"),
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

-- Restore cursor to its last position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group("restore_cursor"),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Resize splits when the host terminal resizes (e.g. tmux/Zellij window).
vim.api.nvim_create_autocmd("VimResized", {
  group = group("resize_splits"),
  command = "tabdo wincmd =",
})

-- Auto-create parent directories on :w of a path that doesn't exist yet.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group("mkdir_on_save"),
  callback = function(ev)
    if ev.match:match("^%w+://") then
      return
    end -- skip URI-style buffers
    local dir = vim.fn.fnamemodify(ev.file, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Autosave on FocusLost (nvim loses focus to another app/window). We iterate
-- buffers explicitly instead of `:wall` so we can skip:
--   * unnamed scratch buffers (writing them would error)
--   * non-normal buftypes (terminal, help, quickfix — never want to write these)
--   * unmodified buffers (avoids touching mtime, which retriggers fs watchers)
-- `:update` already no-ops on unmodified buffers, but the explicit guard keeps
-- intent obvious and leaves a place to add per-buffer opt-outs (e.g.
-- `vim.b.autosave_disabled`) later without re-deriving the conditions.
vim.api.nvim_create_autocmd("FocusLost", {
  group = group("autosave"),
  desc = "Write all modified, named, normal-buftype buffers",
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if
        vim.bo[buf].modified
        and vim.bo[buf].buftype == ""
        and vim.api.nvim_buf_get_name(buf) ~= ""
      then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent! update")
        end)
      end
    end
  end,
})
