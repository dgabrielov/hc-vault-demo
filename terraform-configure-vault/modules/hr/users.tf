# Create a superadmin user within this namespace
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

# Create a standard user within this namespace
resource "vault_generic_endpoint" "hr" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/hr"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["hr"],
  "password": "${var.default_password}"
}
EOT
}