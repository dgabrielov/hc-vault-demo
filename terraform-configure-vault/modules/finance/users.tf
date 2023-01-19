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

# Create a user named superadmin within this namespace
resource "vault_generic_endpoint" "finance" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/finance"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["finance"],
  "password": "${var.default_password}"
}
EOT
}