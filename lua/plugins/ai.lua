-- ============================================================================
-- AI: GitHub Copilot inline + chat. Auth is handled by `:Copilot auth` on
-- first run (browser flow). Token persists in <data>/github-copilot/.
-- ============================================================================

local map = vim.keymap.set

-- ---------- copilot.lua: inline ghost-text suggestions ------------------------
-- We disable copilot's built-in panel/suggestion keymaps because blink.cmp
-- handles completion. Copilot only provides ghost text on idle.
local ok_cop, cop = pcall(require, "copilot")
if ok_cop then
  cop.setup({
    suggestion = { enabled = true, auto_trigger = true, keymap = { accept = "<C-l>" } },
    panel = { enabled = false },
    filetypes = {
      markdown = true,
      gitcommit = true,
      ["*"] = true,
    },
  })
end

-- ---------- CopilotChat: a chat buffer using Copilot as the model ------------
local ok_chat, chat = pcall(require, "CopilotChat")
if ok_chat then
  chat.setup({
    model = "gpt-5.5",
    debug = false,
  })
  map({ "n", "v" }, "<leader>cc", "<cmd>CopilotChat<cr>", { desc = "Copilot Chat" })
  map({ "n", "v" }, "<leader>ce", "<cmd>CopilotChatExplain<cr>", { desc = "Copilot Explain" })
end
