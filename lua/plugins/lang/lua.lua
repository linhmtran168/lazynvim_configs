-- ============================================================================
-- Lua language module. We edit Lua here (this very repo) so this lands first.
-- Note: lazydev.nvim teaches lua_ls about Neovim's runtime API; configured
-- in plugins/lsp.lua, not here.
-- ============================================================================

return {
  servers = {
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = 'Replace' },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
          diagnostics = { globals = { 'vim' } },
        },
      },
    },
  },
  formatters_by_ft = { lua = { 'stylua' } },
  parsers          = { 'lua', 'luadoc', 'vim', 'vimdoc', 'query' },
  mason_tools      = { 'lua-language-server', 'stylua' },
}
