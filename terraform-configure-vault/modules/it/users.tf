
# Create a user named superadmin within this namespace
resource "vault_generic_endpoint" "superadmin" {
  #provider             = vault
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/superadmin"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["superadmin"],
  "password": "${var.default_password}"
}
EOT
}


resource "vault_generic_endpoint" "it_users" {
  depends_on = [vault_auth_backend.userpass]

  for_each = var.it_data

  path                 = "auth/userpass/users/${each.key}"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["${each.key}"],
  "password": "${var.default_password}"
}
EOT
}

resource "vault_generic_endpoint" "ssh_otp" {
  depends_on = [vault_auth_backend.userpass]
  count      = local.enabled.ssh_otp ? 1 : 0

  path                 = "auth/userpass/users/ubuntu"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["ssh-otp"],
  "password": "${var.default_password}"
}
EOT
}