
locals {
  create_ns_it      = var.namespaces.it
  create_ns_it_mfa  = var.namespaces.it_mfa
  create_ns_finance = var.namespaces.finance
  create_ns_hr      = var.namespaces.hr
  #policies_dir = var.policies_dir
}

resource "vault_auth_backend" "userpass_root" {
  type = "userpass"
}

resource "vault_namespace" "it" {
  count = local.create_ns_it ? 1 : 0
  path  = "it"
}

resource "vault_namespace" "it_mfa" {
  count = local.create_ns_it_mfa ? 1 : 0
  path  = "it_mfa"
}

resource "vault_namespace" "finance" {
  count = local.create_ns_finance ? 1 : 0
  path  = "finance"
}

resource "vault_namespace" "hr" {
  count = local.create_ns_hr ? 1 : 0
  path  = "hr"
}

resource "vault_policy" "superadmin" {
  name   = "superadmin"
  policy = file("./policies/superadmin.hcl")
}

# Create a user named superadmin
resource "vault_generic_endpoint" "superadmin" {
  #provider             = vault
  depends_on           = [vault_auth_backend.userpass_root]
  path                 = "auth/userpass/users/superadmin"
  ignore_absent_fields = true

  data_json = <<EOT
{
  "policies": ["superadmin"],
  "password": "${var.default_password}"
}
EOT
}
