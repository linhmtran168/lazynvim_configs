-- ============================================================================
-- Language aggregator.
--
-- Reads every lua/plugins/lang/*.lua file. Each language module returns a
-- table with the shape:
--
--   {
--     servers          = { <lspconfig-name> = { settings = {...} } },
--     formatters_by_ft = { <ft> = { 'formatter1', 'formatter2' } },
--     linters_by_ft    = { <ft> = { 'linter1' } },
--     parsers          = { 'parser1', 'parser2' },
--     mason_tools      = { 'gopls', 'gofumpt', ... },
--     extra_plugins    = { { src = '...' }, ... },
--   }
--
-- All fields are optional. This module merges them into one table consumed
-- by plugins/{lsp,coding,treesitter}.lua and config/pack.lua.
-- ============================================================================

local M = {
  servers = {},
  formatters_by_ft = {},
  linters_by_ft = {},
  parsers = {},
  mason_tools = {},
  extra_plugins = {},
}

local lang_dir = vim.fn.stdpath("config") .. "/lua/plugins/lang"

-- vim.fn.readdir returns {} if the directory doesn't exist yet; safe.
for _, file in ipairs(vim.fn.readdir(lang_dir, [[v:val =~ '\.lua$']])) do
  local name = file:match("(.+)%.lua$")
  local ok, mod = pcall(require, "plugins.lang." .. name)
  if ok and type(mod) == "table" then
    for k, v in pairs(mod.servers or {}) do
      M.servers[k] = v
    end
    for k, v in pairs(mod.formatters_by_ft or {}) do
      M.formatters_by_ft[k] = v
    end
    for k, v in pairs(mod.linters_by_ft or {}) do
      M.linters_by_ft[k] = v
    end
    for _, p in ipairs(mod.parsers or {}) do
      table.insert(M.parsers, p)
    end
    for _, t in ipairs(mod.mason_tools or {}) do
      table.insert(M.mason_tools, t)
    end
    for _, e in ipairs(mod.extra_plugins or {}) do
      table.insert(M.extra_plugins, e)
    end
  elseif not ok then
    vim.notify(("lang module %s failed: %s"):format(name, mod), vim.log.levels.WARN)
  end
end

return M
