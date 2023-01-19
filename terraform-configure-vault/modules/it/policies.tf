resource "vault_policy" "superadmin" {
  name   = "superadmin"
  policy = file("./policies/superadmin.hcl")
}

resource "vault_policy" "it_users" {
  for_each = var.it_data
  name     = each.key
  policy   = file("./policies/${each.key}.hcl")
}

resource "vault_policy" "ssh_role" {
  count  = local.enabled.ssh_otp ? 1 : 0
  name   = "ssh-otp"
  policy = file("./policies/ssh-otp.hcl")
}