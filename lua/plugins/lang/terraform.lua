-- Terraform / HCL: terraform-ls handles both .tf and .hcl. `terraform fmt` runs
-- via conform — must be on PATH (not Mason; ships with the Terraform binary).
return {
  servers = { terraformls = {} },
  formatters_by_ft = { terraform = { "terraform_fmt" }, hcl = { "terraform_fmt" } },
  parsers = { "terraform", "hcl" },
  mason_tools = { "terraform-ls" },
}
