-- Filetypes: gitcommit, gitignore, gitattributes, gitrebase. No LSP server,
-- but parsers + a few formatters keep the experience consistent.
return {
  parsers = { "git_config", "git_rebase", "gitattributes", "gitcommit", "gitignore" },
}
