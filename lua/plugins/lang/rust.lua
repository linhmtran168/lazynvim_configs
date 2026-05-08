return {
  servers = {
    rust_analyzer = {
      settings = {
        ['rust-analyzer'] = {
          cargo = { allFeatures = true },
          checkOnSave = { command = 'clippy' },
          procMacro = { enable = true },
        },
      },
    },
  },
  parsers     = { 'rust', 'ron' },
  mason_tools = { 'rust-analyzer' },
  -- Note: rustfmt + clippy come with the rust toolchain; install via rustup,
  -- not Mason. conform.nvim will pick them up if they're on PATH.
}
