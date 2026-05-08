-- ============================================================================
-- LSP wiring.
--
-- Pipeline:
--   lang/<name>.lua → config.lang aggregator → here.
--
-- We use the Neovim 0.11+ `vim.lsp.config(name, opts)` API to register each
-- server. mason-lspconfig's `automatic_enable` then starts the right server
-- when a buffer of the matching filetype opens.
--
-- LSP-specific keymaps live in the LspAttach callback (buffer-scoped) so they
-- don't pollute non-LSP buffers.
-- ============================================================================

local lang = require("config.lang")

-- Mason: installs LSP servers, formatters, linters, DAPs as binaries under
-- <data>/mason/. mason-tool-installer makes the per-language `mason_tools`
-- list declarative — drift between the manifest and disk is auto-corrected.
require("mason").setup()
require("mason-tool-installer").setup({
  ensure_installed = lang.mason_tools,
  run_on_start = true,
})

-- lazydev: makes lua_ls aware of Neovim's runtime + plugin Lua so completion
-- and goto-definition work when editing config like this file.
local ok_lazydev, lazydev = pcall(require, "lazydev")
if ok_lazydev then
  lazydev.setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      "lazy.nvim",
    },
  })
end

-- Register every server's config blob.
for name, opts in pairs(lang.servers) do
  vim.lsp.config(name, opts)
end

-- mason-lspconfig wires Mason-installed servers to lspconfig + auto-enables.
require("mason-lspconfig").setup({
  ensure_installed = vim.tbl_keys(lang.servers),
  automatic_enable = true,
})

-- ---------- LspAttach: buffer-local keymaps when a server attaches -----------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config_lsp_attach", { clear = true }),
  callback = function(ev)
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = "LSP: " .. desc })
    end

    map("gd", vim.lsp.buf.definition, "Goto Definition")
    map("gr", vim.lsp.buf.references, "References")
    map("gI", vim.lsp.buf.implementation, "Implementation")
    map("gy", vim.lsp.buf.type_definition, "Type Definition")
    map("gD", vim.lsp.buf.declaration, "Declaration")
    map("K", vim.lsp.buf.hover, "Hover")
    map("gK", vim.lsp.buf.signature_help, "Signature Help")
    map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
    -- <leader>cr is owned by inc-rename (set in config/keymaps.lua).
    map("<leader>cR", vim.lsp.buf.rename, "LSP Rename")
    map("<leader>cf", function()
      require("conform").format({ async = true, lsp_format = "fallback" })
    end, "Format")
    map("<leader>cl", "<cmd>checkhealth vim.lsp<cr>", "LSP Info")
  end,
})
