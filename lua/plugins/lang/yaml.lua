-- ============================================================================
-- YAML language module
-- ============================================================================

return {
  servers = { yamlls = { settings = { yaml = { keyOrdering = false } } } },
  formatters_by_ft = { yaml = { 'prettierd', 'prettier', stop_after_first = true } },
  parsers     = { 'yaml' },
  mason_tools = { 'yaml-language-server' },
}
