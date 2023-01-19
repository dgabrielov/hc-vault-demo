resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "vault_mount" "kvv1" {
  path        = "accounting"
  type        = "kv"
  options     = { version = "1" }
  description = "KV Version 1 secret engine mount"
}

resource "vault_kv_secret" "secret" {
  path = "${vault_mount.kvv1.path}/DocuSign"
  data_json = jsonencode(
    {
      HomerSimpson = random_password.password.result
    }
  )
}
