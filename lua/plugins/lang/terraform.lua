return {
  servers = { terraformls = {} },
  formatters_by_ft = { terraform = { "terraform_fmt" }, hcl = { "terraform_fmt" } },
  parsers = { "terraform", "hcl" },
  mason_tools = { "terraform-ls" },
}
