resource "vault_policy" "superadmin" {
  name   = "superadmin"
  policy = file("./policies/superadmin.hcl")
}

resource "vault_policy" "finance" {
  name   = "finance"
  policy = file("./policies/finance.hcl")
}