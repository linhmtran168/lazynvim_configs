-- ============================================================================
-- Git: gutter signs (gitsigns) + in-editor diff/history (diffview).
-- Lazygit lives outside nvim; <leader>gg is wired in plugins/picker.lua via
-- Snacks (it shells out to lazygit; install it separately).
-- ============================================================================

local map = vim.keymap.set

-- ---------- gitsigns: gutter +/-/~, stage/reset hunks, blame ------------------
local ok_gs, gs = pcall(require, "gitsigns")
if ok_gs then
  gs.setup({
    on_attach = function(buf)
      local function bmap(lhs, rhs, desc)
        map("n", lhs, rhs, { buffer = buf, desc = desc })
      end
      bmap("]c", function()
        gs.nav_hunk("next")
      end, "Next Hunk")
      bmap("[c", function()
        gs.nav_hunk("prev")
      end, "Prev Hunk")
      bmap("<leader>hs", gs.stage_hunk, "Stage Hunk")
      bmap("<leader>hr", gs.reset_hunk, "Reset Hunk")
      bmap("<leader>hp", gs.preview_hunk, "Preview Hunk")
      bmap("<leader>hb", function()
        gs.blame_line({ full = true })
      end, "Blame Line")
    end,
  })
end

-- ---------- diffview: in-editor diff + file history ---------------------------
local ok_dv, dv = pcall(require, "diffview")
if ok_dv then
  dv.setup()
end

-- ---------- Lazygit + git pickers (Snacks-driven) -----------------------------
map("n", "<leader>gg", function()
  Snacks.lazygit({ cwd = vim.fs.root(0, ".git") })
end, { desc = "Lazygit (root)" })
map("n", "<leader>gG", function()
  Snacks.lazygit()
end, { desc = "Lazygit (cwd)" })
map("n", "<leader>gb", function()
  Snacks.picker.git_log_line()
end, { desc = "Git Blame Line" })
map("n", "<leader>gf", function()
  Snacks.picker.git_log_file()
end, { desc = "Git File History" })
map("n", "<leader>gl", function()
  Snacks.picker.git_log({ cwd = vim.fs.root(0, ".git") })
end, { desc = "Git Log (root)" })
map("n", "<leader>gL", function()
  Snacks.picker.git_log()
end, { desc = "Git Log (cwd)" })
map("n", "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
map("n", "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
  })
end, { desc = "Git Browse (yank URL)" })

-- ---------- Diffview keymaps (carry over verbatim) ----------------------------
map("n", "<leader>gvo", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
map("n", "<leader>gvc", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
map("n", "<leader>gvf", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview File History" })
map("n", "<leader>gvh", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview Repo History" })
