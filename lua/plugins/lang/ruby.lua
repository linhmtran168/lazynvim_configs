return {
  servers = { ruby_lsp = {} },
  formatters_by_ft = { ruby = { "rubocop" } },
  linters_by_ft = { ruby = { "rubocop" } },
  parsers = { "ruby" },
  mason_tools = { "ruby-lsp", "rubocop" },
}
