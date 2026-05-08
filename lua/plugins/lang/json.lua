-- ============================================================================
-- JSON language module (json, jsonc, json5)
-- ============================================================================

return {
  servers = { jsonls = {} },
  formatters_by_ft = { json = { 'prettierd', 'prettier', stop_after_first = true } },
  parsers     = { 'json', 'jsonc', 'json5' },
  mason_tools = { 'json-lsp', 'prettierd' },
}
