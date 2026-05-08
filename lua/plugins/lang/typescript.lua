return {
  servers = {
    vtsls = {
      settings = {
        typescript = { inlayHints = { parameterNames = { enabled = "all" } } },
        javascript = { inlayHints = { parameterNames = { enabled = "all" } } },
      },
    },
  },
  formatters_by_ft = {
    javascript = { "prettierd", "prettier", stop_after_first = true },
    typescript = { "prettierd", "prettier", stop_after_first = true },
    javascriptreact = { "prettierd", "prettier", stop_after_first = true },
    typescriptreact = { "prettierd", "prettier", stop_after_first = true },
  },
  linters_by_ft = {
    javascript = { "eslint_d" },
    typescript = { "eslint_d" },
  },
  parsers = { "javascript", "typescript", "tsx", "jsdoc" },
  mason_tools = { "vtsls", "prettierd", "eslint_d" },
}
