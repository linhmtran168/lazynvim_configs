-- ============================================================================
-- persistence.nvim: per-cwd session save on :qa, manual restore.
--
-- A "session" here is the set of buffers, window layout, tab pages, options,
-- and folds at the moment of exit. persistence keys sessions by cwd, so each
-- project gets its own saved state under <stdpath('state')>/sessions/.
--
-- We deliberately do NOT auto-load on startup. Two reasons:
--   * `nvim file.txt` should open file.txt, not whatever the cwd's last
--     session contained.
--   * Explicit `<leader>qs` is faster to reason about than "did nvim
--     restore something?" — small startup wins, no surprises.
-- ============================================================================

local ok, persistence = pcall(require, "persistence")
if not ok then
  return
end

-- Defaults: save_dir = <state>/sessions/, options = "buffers,curdir,tabpages,
-- winsize,help,globals,skiprtp,folds". Sensible; no overrides needed.
persistence.setup()

local map = vim.keymap.set

-- <leader>q is also the prefix for "quit" (<leader>qq exists in keymaps.lua).
-- The session bindings round out the namespace into "quit + session" — both
-- are end-of-work-session actions, so the prefix sharing reads naturally.
map("n", "<leader>qs", function()
  persistence.load()
end, { desc = "Restore Session (cwd)" })

map("n", "<leader>ql", function()
  persistence.load({ last = true })
end, { desc = "Restore Last Session" })

map("n", "<leader>qS", function()
  persistence.select()
end, { desc = "Select Session" })

-- "Don't save" — useful when you want to exit without polluting the saved
-- session for this cwd (e.g. you opened a one-off scratch buffer).
map("n", "<leader>qd", function()
  persistence.stop()
  vim.notify("Session won't be saved on exit", vim.log.levels.INFO, { title = "persistence" })
end, { desc = "Don't Save Current Session" })
