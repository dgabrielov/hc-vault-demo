
locals {
  kv_infrakeys    = var.it_data.infra
  kv_helpdeskkeys = var.it_data.helpdesk
  kv_infoseckeys  = var.it_data.infosec
  enabled         = var.use_cases
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_mount" "infra" {
  count   = local.enabled.kv_v2 ? 1 : 0
  path    = "infra"
  type    = "kv"
  options = { version = "2" }
  #description = "Infrastructure admin credentials"
}

resource "vault_kv_secret_v2" "infra" {
  depends_on = [
    vault_mount.infra
  ]
  count               = local.enabled.kv_v2 ? length(local.kv_infrakeys) : 0
  mount               = element(vault_mount.infra[*].path, count.index)
  name                = element(local.kv_infrakeys[*], count.index)
  cas                 = 1
  delete_all_versions = false
  data_json = jsonencode(
    {
      HomerSimpson = random_password.password.result
    }
  )
}



resource "vault_mount" "helpdesk" {
  count = local.enabled.kv_v2 ? 1 : 0
  path  = "helpdesk"
  type  = "kv-v2"
  #description = "Infrastructure admin credentials"
}

resource "vault_kv_secret_v2" "helpdesk" {
  count               = local.enabled.kv_v2 ? length(local.kv_helpdeskkeys) : 0
  mount               = element(vault_mount.helpdesk[*].path, count.index)
  name                = element(local.kv_helpdeskkeys[*], count.index)
  cas                 = 1
  delete_all_versions = false
  data_json = jsonencode(
    {
      NedFlanders = random_password.password.result
    }
  )
}

resource "vault_mount" "infosec" {
  count = local.enabled.kv_v2 ? 1 : 0
  path  = "infosec"
  type  = "kv-v2"
  #description = "Infrastructure admin credentials"
}

resource "vault_kv_secret_v2" "infosec" {
  count               = local.enabled.kv_v2 ? length(local.kv_infoseckeys) : 0
  mount               = element(vault_mount.infosec[*].path, count.index)
  name                = element(local.kv_infoseckeys[*], count.index)
  cas                 = 1
  delete_all_versions = false
  data_json = jsonencode(
    {
      BartSimpson = random_password.password.result
    }
  )
}

resource "vault_mount" "ssh_otp" {
  count       = local.enabled.ssh_otp ? 1 : 0
  path        = "ssh"
  type        = "ssh"
  description = "engine for managing privileged ssh sessions"
}

resource "vault_ssh_secret_backend_role" "ssh_otp_key_role" {
  count        = local.enabled.ssh_otp ? 1 : 0
  name         = "otp_key_role"
  backend      = element(vault_mount.ssh_otp[*].path, count.index)
  default_user = "ubuntu"
  key_type     = "otp"
  cidr_list    = "0.0.0.0/0"
}


resource "vault_database_secrets_mount" "psql" {
  count = local.enabled.db.postgres ? 1 : 0
  path = "database/hr"
  default_lease_ttl_seconds = "1800"
  max_lease_ttl_seconds = "3600"

  postgresql {
    name              = "postgres"
    username          = "pgroot"
    password          = "changeme"
    connection_url    = "postgresql://{{username}}:{{password}}@localhost:15432/postgres?sslmode=disable"
    verify_connection = true
    plugin_name = "postgresql-database-plugin"
    allowed_roles = [
      "*"
    ]
  }
}


resource "vault_database_secret_backend_role" "dbuser" {
  count = local.enabled.db.postgres ? 1 : 0
  name    = "dbuser"
  backend = element(vault_database_secrets_mount.psql[*].path, count.index)
  db_name = element(vault_database_secrets_mount.psql[*].postgresql[0].name, count.index)
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT; GRANT dbuser TO \"{{name}}\";"
  ]
}

resource "vault_database_secret_backend_role" "dbadmin" {
  count = local.enabled.db.postgres ? 1 : 0
  name    = "dbadmin"
  backend = element(vault_database_secrets_mount.psql[*].path, count.index)
  db_name = element(vault_database_secrets_mount.psql[*].postgresql[0].name, count.index)
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT; GRANT dbadmin TO \"{{name}}\";"
  ]
}


