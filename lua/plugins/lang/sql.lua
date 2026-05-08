return {
  servers = { sqlls = {} },
  formatters_by_ft = { sql = { "sql_formatter" } },
  parsers = { "sql" },
  mason_tools = { "sqlls", "sql-formatter" },
}
