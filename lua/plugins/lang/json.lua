-- ============================================================================
-- JSON language module (json, jsonc, json5)
-- ============================================================================

return {
  servers = { jsonls = {} },
  formatters_by_ft = { json = { 'prettierd', 'prettier', stop_after_first = true } },
  parsers     = { 'json', 'json5' },  -- jsonc is bundled with Neovim 0.12, no install needed
  mason_tools = { 'json-lsp', 'prettierd' },
}
