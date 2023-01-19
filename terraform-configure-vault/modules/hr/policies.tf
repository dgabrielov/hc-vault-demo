resource "vault_policy" "superadmin" {
  name   = "superadmin"
  policy = file("./policies/superadmin.hcl")
}

resource "vault_policy" "hr" {
  name   = "hr"
  policy = file("./policies/hr.hcl")
}