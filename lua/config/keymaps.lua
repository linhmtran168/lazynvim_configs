-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>m", function()
  require("grapple").toggle()
end, { desc = "Toggle File Tag" })

map("n", "<leader>M", function()
  require("grapple").toggle_tags()
end, { desc = "Open File Tags" })

map("n", "]m", function()
  require("grapple").cycle_tags("next")
end, { desc = "Next File Tag" })

map("n", "[m", function()
  require("grapple").cycle_tags("prev")
end, { desc = "Prev File Tag" })

map("n", "<leader>1", function()
  require("grapple").select({ index = 1 })
end, { desc = "Jump to Tag 1" })

map("n", "<leader>2", function()
  require("grapple").select({ index = 2 })
end, { desc = "Jump to Tag 2" })

map("n", "<leader>3", function()
  require("grapple").select({ index = 3 })
end, { desc = "Jump to Tag 3" })

map("n", "<leader>4", function()
  require("grapple").select({ index = 4 })
end, { desc = "Jump to Tag 4" })

map({ "n", "t" }, "<C-`>", function()
  Snacks.terminal()
end, { desc = "Terminal (cwd)" })

map("n", "<leader>t`", function()
  Snacks.terminal(nil, { cwd = LazyVim.root() })
end, { desc = "Terminal (Root Dir)" })

map("n", "<leader>gvo", "<cmd>DiffviewOpen<cr>", { desc = "Diffview Open" })
map("n", "<leader>gvc", "<cmd>DiffviewClose<cr>", { desc = "Diffview Close" })
map("n", "<leader>gvf", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diffview File History" })
map("n", "<leader>gvh", "<cmd>DiffviewFileHistory<cr>", { desc = "Diffview Repo History" })

map("v", "<D-c>", '"+y', { noremap = true, silent = true, desc = "Copy to system clipboard" })
