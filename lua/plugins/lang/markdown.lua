-- ============================================================================
-- Markdown language module
-- ============================================================================

return {
  servers = { marksman = {} },
  formatters_by_ft = { markdown = { 'prettierd', 'prettier', stop_after_first = true } },
  linters_by_ft = { markdown = { 'markdownlint' } },
  parsers     = { 'markdown', 'markdown_inline' },
  mason_tools = { 'marksman', 'markdownlint' },
}
