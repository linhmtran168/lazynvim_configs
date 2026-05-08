-- Ruby: ruby-lsp (Shopify) is the modern choice; lighter and better-maintained
-- than solargraph. Rubocop covers both formatting and linting via conform/lint.
return {
  servers = { ruby_lsp = {} },
  formatters_by_ft = { ruby = { "rubocop" } },
  linters_by_ft = { ruby = { "rubocop" } },
  parsers = { "ruby" },
  mason_tools = { "ruby-lsp", "rubocop" },
}
