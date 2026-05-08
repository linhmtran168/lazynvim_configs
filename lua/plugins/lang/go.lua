return {
  servers = {
    gopls = {
      settings = {
        gopls = {
          gofumpt = true,
          analyses = { unusedparams = true, shadow = true },
          staticcheck = true,
          hints = { parameterNames = true, assignVariableTypes = true },
        },
      },
    },
  },
  formatters_by_ft = { go = { "gofumpt", "goimports" } },
  linters_by_ft = { go = { "golangcilint" } },
  parsers = { "go", "gomod", "gosum", "gowork" },
  mason_tools = { "gopls", "gofumpt", "goimports", "golangci-lint" },
}
