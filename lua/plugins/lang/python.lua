return {
  servers = {
    pyright = {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = 'basic',
            diagnosticMode = 'workspace',
            useLibraryCodeForTypes = true,
          },
        },
      },
    },
  },
  formatters_by_ft = { python = { 'ruff_format', 'ruff_organize_imports' } },
  linters_by_ft = { python = { 'ruff' } },
  parsers     = { 'python' },
  mason_tools = { 'pyright', 'ruff' },
}
