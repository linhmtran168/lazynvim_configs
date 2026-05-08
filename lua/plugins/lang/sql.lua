-- SQL: sqlls gives basic completion; sql-formatter normalizes whitespace.
-- For dialect-aware linting (postgres/mysql), add `sqlfluff` to mason_tools and
-- linters_by_ft once the project warrants it.
return {
  servers = { sqlls = {} },
  formatters_by_ft = { sql = { "sql_formatter" } },
  parsers = { "sql" },
  mason_tools = { "sqlls", "sql-formatter" },
}
